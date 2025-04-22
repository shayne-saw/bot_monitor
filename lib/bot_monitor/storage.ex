defmodule BotMonitor.Storage do
  @moduledoc """
  A module for handling persistent storage using DETS.

  This module provides functions to store and retrieve configuration data and cookies
  using the DETS (Disk-based Erlang Term Storage) system. It ensures cross-platform
  compatibility by dynamically determining the storage location based on the operating
  system.
  """

  @table :data

  @doc """
  Opens the DETS table, executes the given function, and ensures the table is closed
  afterward.

  This function is a utility to safely manage the lifecycle of the DETS table. It
  ensures that the table is properly opened before executing the provided function and
  closed afterward, regardless of whether the function succeeds or raises an error.

  ## Parameters
    - `fun`: A lambda function to execute while the DETS table is open.

  ## Returns
    - The result of the executed function.

  ## Raises
    - An error if the DETS table cannot be opened.

  ## Examples

      iex> BotMonitor.Storage.open(fn -> BotMonitor.Storage.get_cookie() end)
      "randomlyGeneratedBase64Cookie=="

      iex> BotMonitor.Storage.open(fn -> BotMonitor.Storage.set_config(%{username: "user"}) end)
      :ok
  """
  def open(fun) do
    case :dets.open_file(@table, file: dets_file_path("data")) do
      {:ok, _} ->
        result = fun.()
        :dets.close(@table)
        result

      {:error, reason} ->
        raise "Failed to open DETS table: #{inspect(reason)}"
    end
  end

  @doc """
  Retrieves the cookie from DETS storage.

  If the cookie does not exist, a new one is generated, stored in DETS, and returned.

  ## Returns
    - The cookie as a Base64-encoded string.

  ## Examples

      iex> BotMonitor.Storage.get_cookie()
      "randomlyGeneratedBase64Cookie=="
  """
  def get_cookie do
    case :dets.lookup(@table, :cookie) do
      [] ->
        cookie =
          :crypto.strong_rand_bytes(16)
          |> Base.encode64()

        :dets.insert(@table, {:cookie, cookie})
        cookie

      [{:cookie, cookie}] ->
        cookie
    end
  end

  @doc """
  Retrieves the configuration from DETS storage.

  ## Returns
    - The configuration as a map if it exists.
    - `nil` if no configuration is found.

  ## Examples

      iex> BotMonitor.Storage.get_config()
      %{username: "user", log_directory: "/path/to/logs", socket_endpoint: "ws://localhost:4000"}
  """
  def get_config() do
    case :dets.lookup(@table, :config) do
      [] -> nil
      [{:config, config}] -> config
    end
  end

  @doc """
  Stores the given configuration in DETS storage.

  ## Parameters
    - `config`: A map containing the configuration to store.

  ## Examples

      iex> BotMonitor.Storage.set_config(%{username: "user", log_directory: "/path/to/logs"})
      :ok
  """
  def set_config(config) do
    :dets.insert(@table, {:config, config})
  end

  @doc """
  Determines the file path for DETS storage based on the operating system.

  ## Parameters
    - `filename`: The name of the DETS file.

  ## Returns
    - The full path to the DETS file as a charlist.

  ## Examples

      iex> BotMonitor.Storage.dets_file_path("data")
      '/home/user/.local/share/bot_monitor/data'
  """
  defp dets_file_path(filename) do
    base_dir =
      case(:os.type()) do
        {:win32, _} -> System.fetch_env!("LOCALAPPDATA")
        {:unix, _} -> Path.join([System.fetch_env!("HOME"), ".local", "share"])
      end

    Path.join([base_dir, "bot_monitor", filename])
    |> tap(&File.mkdir_p!(Path.dirname(&1)))
    |> String.to_charlist()
  end
end
