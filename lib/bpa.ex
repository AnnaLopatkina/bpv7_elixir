defmodule Bpv7.BPA do
  use Agent
  use GenServer

  @doc """
  Starts a new Instance of the Bundle Protocol Agent (BPA)

  The BPA has an Agent which holds a map with the eid as key and a tuple {protocol, host, port, avail_begin, avail_end}.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: :nodes)
    Agent.start_link(fn -> %{} end, name: :bundles)
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  def add_tcp_node(eid, host, port, avail_begin, avail_end) do
    :ok = Agent.update(:nodes, &Map.put(&1, eid, {:tcp, host, port, avail_begin, avail_end}))
  end

  def get_connection_method(eid) do
    {method, _, _, _, _} = Agent.get(:nodes, &Map.get(&1, eid))
    method
  end

  def get_tcp_conn_details(eid) do
    {:tcp, host, port, _, _ } = Agent.get(:nodes, &Map.get(&1, eid))
    {host, port}
  end

  def get_availability(eid) do
    {_, _, _, avail_begin, avail_end} = Agent.get(:nodes, &Map.get(&1, eid))
    {avail_begin, avail_end}
  end

  def schedule_bundle(bundle, eid) do
    {avail_begin, avail_end} = get_availability(eid)
    current_time = DateTime.utc_now()
    schedule_time = DateTime.diff(avail_begin, current_time)
    schedule_time = cond do
      schedule_time < 0 ->
        0
      true ->
        schedule_time * 1000
    end
    Process.send_after(__MODULE__,{:send, bundle, eid}, schedule_time)
    :ok
  end

  def handle_info({:send, bundle, eid}, state) do
    :tcp = get_connection_method(eid)
    {host, port} = get_tcp_conn_details(eid)
    connState = Bpv7.ConnManager.check_connection(host, port)
    case connState do
      :not_found -> :ok = Bpv7.ConnManager.connect(host, port)
      :ok -> nil
    end
    bundle_updated_AgeBlock = Bpv7.Bundle_Manager.update_bundleAgeBlock(bundle)
    Bpv7.ConnManager.send(host, port, bundle_updated_AgeBlock)
    {:noreply, state}
  end

end