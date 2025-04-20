defmodule BotMonitor.DirWatcher do
  alias BotMonitor.LogParser
  use GenServer

  @log_dir_env_name "LOG_DIRECTORY"
  @log_file_pattern ~r/^eqlog_(\w+)_P1999Green\.txt$/
  @poll_interval 1_000

  # API

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks

  def init([]) do
    directory = System.get_env(@log_dir_env_name)
    IO.inspect("Starting with directory: #{directory}")

    [{character, _, path} | _] = list_files_info(directory)
    LogParser.start_link(character, path)

    :timer.send_interval(@poll_interval, self(), :poll)
    {:ok, %{directory: directory, active_character: character}}
  end

  def handle_info(:poll, %{directory: directory} = state) do
    [{character, _, path} | _] = list_files_info(directory)

    if character != state.active_character do
      LogParser.stop(character)
      LogParser.start_link(character, path)
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
