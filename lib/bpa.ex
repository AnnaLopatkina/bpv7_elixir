defmodule Bpv7.BPA do
  use Agent

  @doc """
  Starts a new Instance of the Bundle Protocol Agent (BPA)

  The BPA has an Agent which holds a map with the eid as key and a tuple {protocol, host, port, avail_begin, avail_end}.
  """
  def start(_opts) do
    node_name = :BPA_nodes
    bundle_name =  :BPA_bundles
    Agent.start_link(fn -> %{} end, name: :nodes)
    Agent.start_link(fn -> %{} end, name: :bundles)
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

end