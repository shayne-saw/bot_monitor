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
        {get_config(), Storage.get_cookie()}
      end)

    children = [
      # Starts a worker by calling: BotMonitor.Worker.start_link(arg)
      {Registry, keys: :unique, name: BotMonitor.LogParser},
      {BotMonitor.SocketClient, [config, cookie]}
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
end
