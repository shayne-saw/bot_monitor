defmodule BotMonitor.LogParser do
  alias BotMonitor.SocketClient
  use GenServer

  @welcome_entry_pattern ~r/Welcome to EverQuest\!$/
  @log_entry_pattern ~r/^\[(?<timestamp>[^\]]+)\] (?<message>.*)$/
  @log_timestamp_format "{WDshort} {Mshort} {D} {h24}:{m}:{s} {YYYY}"
  @poll_interval 50

  # API

  def start_link(character, file_path, patterns) do
    GenServer.start_link(__MODULE__, [character, file_path, patterns],
      name: {:via, Registry, {__MODULE__, character}}
    )
  end

  def stop(character) do
    GenServer.stop({:via, Registry, {__MODULE__, character}})
  end

  # Callbacks

  def init([character, file_path, patterns]) do
    file = File.open!(file_path, [:read])
    set_initial_position(file)
    lines_stream(file) |> Stream.run()

    :timer.send_interval(@poll_interval, :poll)
    {:ok, %{character: character, file: file, patterns: patterns}}
  end

  def handle_info(:poll, state) do
    lines_stream(state.file)
    |> Stream.flat_map(fn {timestamp, entry} ->
      Stream.flat_map(state.patterns, fn pattern ->
        case Regex.named_captures(pattern["regex"], entry) do
          nil ->
            []

          captures ->
            [
              %{
                event: pattern["event"],
                character: state.character,
                timestamp:
                  timestamp
                  |> Timex.parse!(@log_timestamp_format)
                  |> Timex.to_datetime(Timex.Timezone.local()),
                captures: captures
              }
            ]
        end
      end)
    end)
    |> Stream.each(&SocketClient.send_entry/1)
    |> Stream.run()

    {:noreply, state}
  end

  def terminate(_reason, state) do
    :file.close(state.file)
    :ok
  end

  # Helper functions

  def lines_stream(file) do
    Stream.resource(
      fn -> file end,
      fn file ->
        with line when is_binary(line) <- IO.read(file, :line),
             [_line, timestamp, message] <- Regex.run(@log_entry_pattern, line) do
          {[{timestamp, message}], file}
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
