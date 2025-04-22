defmodule BotMonitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias BotMonitor.Storage

  use Application

  @impl true
  def start(_type, _args) do
    {config, cookie} =
      Storage.open(fn ->
        {get_config(), BotMonitor.Storage.get_cookie()}
      end)

    children = [
      # Starts a worker by calling: BotMonitor.Worker.start_link(arg)
      {Registry, keys: :unique, name: BotMonitor.LogParser},
      {BotMonitor.DirWatcher, [config]}
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

    dets_config =
      if env_config |> Map.values() |> Enum.any?(&is_nil/1),
        do: BotMonitor.Storage.get_config(),
        else: %{}

    gets_config =
      if is_nil(dets_config),
        do:
          %{
            username: IO.gets("Username: ") |> String.trim(),
            log_directory: IO.gets("Log Directory: ") |> String.trim(),
            log_endpoint: IO.gets("Log Endpoint: ") |> String.trim()
          }
          |> tap(&Storage.set_config/1),
        else: %{}

    cond do
      dets_config && Enum.any?(dets_config) -> dets_config
      Enum.any?(gets_config) -> gets_config
      true -> env_config
    end
  end
end
