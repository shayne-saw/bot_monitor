defmodule BotMonitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias BotMonitor.Storage

  use Application

  @built_at DateTime.utc_now() |> DateTime.to_string()

  @git_hash (case(System.cmd("git", ["rev-parse", "--short", "HEAD"])) do
               {hash, 0} ->
                 dirty_suffix =
                   case System.cmd("git", ["status", "--porcelain"]) do
                     # No changes
                     {"", 0} -> ""
                     _ -> " (dirty)"
                   end

                 String.trim(hash) <> dirty_suffix

               _ ->
                 "unknown"
             end)

  @impl true
  def start(_type, _args) do
    # Print version and Git hash
    print_version_and_git_hash()

    {config, cookie, patterns} =
      Storage.open(fn ->
        {get_config(), Storage.get_cookie(), Storage.get_patterns()}
      end)

    children = [
      # Starts a worker by calling: BotMonitor.Worker.start_link(arg)
      {Registry, keys: :unique, name: BotMonitor.LogParser},
      {BotMonitor.SocketClient, [config, cookie, patterns]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_config() do
    env_config = %{
      username: System.get_env("BOT_MONITOR_USERNAME"),
      log_directory: System.get_env("LOG_DIRECTORY"),
      log_endpoint: System.get_env("LOG_ENDPOINT")
    }

    if env_config |> Map.values() |> Enum.all?(&is_binary/1),
      do: env_config,
      else: get_dets_config()
  end

  def get_dets_config() do
    case Storage.get_config() do
      nil ->
        prompt_user_for_config()
        |> tap(&Storage.set_config/1)

      config ->
        config
    end
  end

  def prompt_user_for_config() do
    %{
      username: prompt_for_value("Username"),
      log_directory: prompt_for_value("Log Directory"),
      log_endpoint: prompt_for_value("Log Endpoint")
    }
  end

  defp prompt_for_value(field) do
    case IO.gets("#{field}: ") |> String.trim() do
      "" ->
        IO.puts("#{field} cannot be empty. Please try again.")
        prompt_for_value(field)

      value ->
        value
    end
  end

  defp print_version_and_git_hash do
    version = Application.spec(:bot_monitor, :vsn) |> to_string()

    IO.puts("BotMonitor Version: #{version}")
    IO.puts("Built At: #{@built_at}")
    IO.puts("Git Hash: #{@git_hash}")
  end
end
