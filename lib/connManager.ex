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
     socket = Agent.get(__MODULE__, &Map.get(&1, {host, port}))
     :ok = :gen_tcp.send(socket, packet)
  end

end