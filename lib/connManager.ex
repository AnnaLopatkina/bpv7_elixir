defmodule Bpv7.ConnManager do
  use Agent
  require Logger
  @moduledoc """
  The Connection Manager (ConnManager) makes it possible to connect to other hosts and send packets there.
  It sends raw binary data.
  The ConnManager also keeps track of all establish connections.
  """


  @doc """
  Starts a new Instance of the connection manager.
  """
  def start(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Checks if there is a connection to a specific Host and Port.

  ## Parameters

  - host: Hostname or IP address as charlist
  - port: Port to connect to
  """
  def check_connection(host, port) do
    socket = Agent.get(__MODULE__, &Map.get(&1, {host, port}))
    case socket do
      nil -> :not_found
      _ -> :ok
    end
  end

  def check_connection?(host, port) do
    case check_connection(host, port) do
      :ok -> true
      :not_found -> false
    end
  end

  @doc """
  Connects to a given host and port.

  ## Parameters

  - host: Hostname or IP address as charlist
  - port: Port to connect to

  ## Examples

  There is a connectable peer:
    iex> Bpv7.ConnManager.connect('localhost', 4040)
    :ok

  There is no peer to connect to:
    iex> Bpv7.ConnManager.connect('localhost', 4042)
    {:error, :econnrefused}
  """
  def connect(host, port) do
    result =
      with {:ok, socket} <- :gen_tcp.connect(host, port, [:binary]),
           do: Agent.update(__MODULE__, &Map.put(&1, {host, port}, socket))
    result
   end

   def send(host, port, packet) do
     socket = get_socket(host, port)
     :ok = :gen_tcp.send(socket, packet)
  end

  def disconnect(host, port) do
    socket = get_socket(host, port)
    unless socket == nil do
      :gen_tcp.shutdown(socket, :read_write)
    end
    :ok
  end

  defp get_socket(host, port) do
    Agent.get(__MODULE__, &Map.get(&1, {host, port}))
  end

end