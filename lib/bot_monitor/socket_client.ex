defmodule BotMonitor.SocketClient do
  @moduledoc """
  A WebSocket client for interacting with the BotBoard server.

  This module uses the `Slipstream` library to manage WebSocket connections,
  handle pairing, and send log entries to the server. It also integrates with
  the `DirWatcher` module to monitor directories for changes.

  ## Features
    - Establishes a WebSocket connection to the server.
    - Handles user pairing when required.
    - Sends log entries to the server.
    - Manages disconnections gracefully.
    - Once successfully paired, starts the DirWatcher process to monitor
      directories and subsequently tail log files.
  """

  require Logger
  alias BotMonitor.Storage
  alias BotMonitor.DirWatcher
  use Slipstream

  # API

  @doc """
  Starts the `SocketClient` process.

  ## Parameters
    - `args`: A list containing the configuration and cookie.

  ## Returns
    - `{:ok, pid}` on success.

  ## Examples

      iex> BotMonitor.SocketClient.start_link([config, cookie])
      {:ok, #PID<0.123.0>}
  """
  def start_link([config, cookie, patterns]) do
    Slipstream.start_link(__MODULE__, [config, cookie, patterns], name: __MODULE__)
  end

  @doc """
  Sends a pairing request to the server with the given code.

  ## Parameters
    - `code`: The pairing code provided by the user.

  ## Returns
    - `true` if the pairing is successful.
    - `false` if the pairing fails.

  ## Examples

      iex> BotMonitor.SocketClient.pair("123456")
      true
  """
  @spec pair(String.t()) :: boolean()
  def pair(code) do
    GenServer.call(__MODULE__, {:pair, code})
  end

  @doc """
  Sends a log entry to the server.

  ## Parameters
    - `entry`: A map containing the log entry data.

  ## Returns
    - `true` if the entry is accepted.
    - `false` if the entry is ignored.

  ## Examples

      iex> BotMonitor.SocketClient.send_entry(%{message: "Log message"})
      true
  """
  @spec send_entry(map()) :: boolean()
  def send_entry(entry) when is_map(entry) do
    GenServer.cast(__MODULE__, {:send_entry, entry})
  end

  # Callbacks

  @doc false
  @impl Slipstream
  def init([config, cookie, patterns]) do
    connect_loop(config, cookie, patterns)
  end

  @doc false
  @impl Slipstream
  def handle_call({:pair, code}, _from, socket) do
    {:reply, check_code(socket, code), socket}
  end

  @doc false
  @impl Slipstream
  def handle_cast({:send_entry, entry}, socket) do
    IO.puts(entry |> Jason.encode!())

    {:ok, _result} =
      socket
      |> push!("logs", "entry", entry)
      |> await_reply!()

    {:noreply, socket}
  end

  @doc false
  @impl Slipstream
  def handle_disconnect(reason, socket) do
    IO.inspect(reason, label: "Disconnected from server")
    {:stop, reason, socket}
  end

  # Helpers

  def connect_loop(config, cookie, patterns) do
    case try_connect(config, cookie, patterns) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, reason} ->
        Logger.error("Connection error: #{inspect(reason)}")
        :timer.sleep(5000)
        connect_loop(config, cookie, patterns)
    end
  end

  @doc false
  def try_connect(config, cookie, patterns) do
    payload = %{
      "username" => config.username,
      "cookie" => cookie,
      "manual_pairing" => Code.ensure_loaded(IEx) && IEx.started?(),
      "pattern_hash" =>
        patterns
        |> :erlang.term_to_binary()
        |> then(&:crypto.hash(:md5, &1))
        |> Base.encode64()
    }

    # Synchronously connect to the websocket server and join the "logs" channel.
    socket =
      connect!(uri: config.log_endpoint)
      |> await_connect!()
      |> join("logs", payload)
      |> await_join!("logs")

    # We will get a message from the server that indicates if we have the latest
    # patterns. If not, it will send them to us and we should save them.
    latest_patterns =
      case await_message!("logs", "pattern_status", _) do
        {_, _, %{"pattern_status" => true}} ->
          patterns

        {_, _, %{"pattern_status" => encoded_patterns}} ->
          patterns =
            encoded_patterns
            |> Enum.map(fn pattern ->
              Map.put(pattern, "regex", Regex.compile!(pattern["regex"]))
            end)

          Storage.open(fn ->
            Storage.set_patterns(patterns)
          end)

          patterns
      end

    # The server will check the provided cookie and indicate if the pairing
    # process is required and convey that via an initial message we wait for
    # here.
    {_, _, user_status} =
      await_message!("logs", "user_status", _)

    if user_status["pairing_required"] do
      interactive_pairing(socket)
    end

    # Finally, start the DirWatcher process to monitor directories.
    {:ok, _pid} = DirWatcher.start_link([config, latest_patterns])
    {:ok, socket}
  rescue
    error -> {:error, error}
  end

  @doc false
  defp interactive_pairing(socket) do
    code = IO.gets("Pairing code: ") |> String.trim()

    if check_code(socket, code),
      do: {:ok, socket},
      else: interactive_pairing(socket)
  end

  @doc false
  defp check_code(socket, code) do
    case socket
         |> push!("logs", "pair", %{code: code})
         |> await_reply! do
      {:ok, result} -> result
      {:error, reason} -> raise "Error pairing: #{reason}"
    end
  end
end
