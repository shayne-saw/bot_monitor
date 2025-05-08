defmodule BotMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_monitor,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BotMonitor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:slipstream, "~> 1.2"},
      {:timex, "~> 3.7"},
      {:websocket_client, "~> 1.5"}
    ]
  end

  defp releases do
    [
      # Include current timestamp in the release name to avoid
      # caching issues. I think there is a way to do this without
      # the timestamp, but I haven't figured it out yet.
      "bot_monitor_#{build_timestamp()}": [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  defp build_timestamp() do
    DateTime.utc_now()
    |> DateTime.to_string()
    |> String.replace(~r"\.\d+Z$", "")
    |> String.replace(~r"[\-\:\s]", "_")
  end
end
