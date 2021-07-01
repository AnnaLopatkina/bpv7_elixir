defmodule Bpv7.ConnManager do
  use Agent
  require Logger


  @doc """
  Starts a new Instance of the connection manager
  """
  def start(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def check_connection(host, port) do
    socket = Agent.get(__MODULE__, &Map.get(&1, {host, port}))
    case socket do
      nil -> :not_found
      _ -> case :gen_tcp.send(socket, "") do
           {:error,:closed} -> :closed

           end
    end
  end

  def connect(host, port) do
    {:ok, socket} = :gen_tcp.connect(host, port, [{:inet_backend, socket}])
    Agent.update(__MODULE__, &Map.put(&1, {host, port}, socket))
   end

   def send(host, port, packet) do
     socket = Agent.get(__MODULE__, &Map.get(&1, {host, port}))
     :ok = :gen_tcp.send(socket, packet)
  end

end