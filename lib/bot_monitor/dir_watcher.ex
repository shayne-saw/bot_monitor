defmodule BotMonitor.DirWatcher do
  alias BotMonitor.LogParser
  use GenServer

  @log_file_pattern ~r/^eqlog_(\w+)_P1999Green\.txt$/
  @poll_interval 1_000

  # API

  def start_link([config, patterns]) do
    GenServer.start_link(__MODULE__, [config, patterns], name: __MODULE__)
  end

  # Callbacks

  def init([config, patterns]) do
    directory = config.log_directory
    IO.inspect("Starting with directory: #{directory}")

    [{character, _, path} | _] = list_files_info(directory)
    LogParser.start_link(character, path, patterns)

    :timer.send_interval(@poll_interval, self(), :poll)
    {:ok, %{directory: directory, active_character: character, patterns: patterns}}
  end

  def handle_info(:poll, state) do
    [{character, _, path} | _] = list_files_info(state.directory)

    if character != state.active_character do
      LogParser.stop(character)
      LogParser.start_link(character, path, state.patterns)
    end

    {:noreply, %{state | active_character: character}}
  end

  # Helper functions

  def list_files_info(directory) do
    directory
    |> File.ls!()
    |> Enum.filter(fn file ->
      file =~ @log_file_pattern
    end)
    |> Enum.map(fn file ->
      [_, character] = Regex.run(@log_file_pattern, file)
      path = Path.join(directory, file)
      stats = File.stat!(path)
      modified_at = NaiveDateTime.from_erl!(stats.mtime)
      {character, modified_at, path}
    end)
    |> Enum.sort_by(fn {_, modified_at, _} -> modified_at end, :desc)
  end
end
