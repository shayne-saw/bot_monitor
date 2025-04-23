defmodule BotMonitor.LogParser do
  use GenServer

  @welcome_entry_pattern ~r/Welcome to EverQuest\!$/
  @log_entry_pattern ~r/^\[(?<timestamp>[^\]]+)\] (?<message>.*)$/
  @log_timestamp_format "{WDshort} {Mshort} {D} {h24}:{m}:{s} {YYYY}"
  @poll_interval 50

  # API

  def start_link(character, file_path) do
    GenServer.start_link(__MODULE__, [character, file_path],
      name: {:via, Registry, {__MODULE__, character}}
    )
  end

  def stop(character) do
    GenServer.stop({:via, Registry, {__MODULE__, character}})
  end

  # Callbacks

  def init([_character, file_path]) do
    file = File.open!(file_path, [:read])
    set_initial_position(file)

    lines_stream(file)
    |> Enum.each(&IO.inspect/1)

    :timer.send_interval(@poll_interval, :poll)
    {:ok, file}
  end

  def handle_info(:poll, file) do
    lines_stream(file)
    |> Enum.each(&IO.inspect/1)

    {:noreply, file}
  end

  def terminate(_reason, file) do
    :file.close(file)
    :ok
  end

  # Helper functions

  def lines_stream(file) do
    Stream.resource(
      fn -> file end,
      fn file ->
        with line when is_binary(line) <- IO.read(file, :line),
             [_line, timestamp, message] <- Regex.run(@log_entry_pattern, line) do
          {:ok, datetime} = Timex.parse(timestamp, @log_timestamp_format)
          {[{datetime, message}], file}
        else
          :eof -> {:halt, file}
          nil -> {[], file}
        end
      end,
      &Function.identity/1
    )
  end

  def set_initial_position(file, milestone \\ 0) do
    case IO.read(file, :line) do
      line when is_binary(line) ->
        if Regex.match?(@welcome_entry_pattern, line) do
          {:ok, position} = :file.position(file, :cur)
          set_initial_position(file, position)
        else
          set_initial_position(file, milestone)
        end

      :eof ->
        :file.position(file, milestone)
        :ok
    end
  end
end
