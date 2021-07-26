defmodule Bpv7.BPA do
  use Agent
  use GenServer
  require Logger

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
    method =
      case Agent.get(:nodes, &Map.get(&1, eid)) do
        {method, _, _, _, _} -> method
        nil -> :not_found
      end
    method
  end

  def get_tcp_conn_details(eid) do
    details =
      case Agent.get(:nodes, &Map.get(&1, eid)) do
        {:tcp, host, port, _, _ } -> {host, port}
        nil -> :not_found
      end
    details
  end

  def get_availability(eid) do
    details =
      case Agent.get(:nodes, &Map.get(&1, eid)) do
        {_, _, _, avail_begin, avail_end} -> {avail_begin, avail_end}
        nil -> :not_found
      end
    details
  end

  def schedule_bundle(bundle, eid) do
    {schedule_task, schedule_time} =
    case get_availability(eid) do
      {avail_begin, avail_end} ->
        current_time = DateTime.utc_now()
        schedule_time = DateTime.diff(avail_begin, current_time)
        schedule_time = cond do
          schedule_time < 0 ->
            0
          true ->
            schedule_time * 1000
        end
        {:send, schedule_time}
      :not_found ->
        Logger.info("No configuration found for #{eid}. Trying again in 5 seconds.")
        {:schedule, 5000}
    end
    Process.send_after(__MODULE__,{schedule_task, bundle, eid}, schedule_time)
    :ok
  end

  def handle_info({:schedule, bundle, eid}, state) do
    schedule_bundle(bundle, eid)
    {:noreply, state}
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
    bundle_encoded = CBOR.encode(%CBOR.Tag{tag: :bytes, value: bundle_updated_AgeBlock})
    Bpv7.ConnManager.send(host, port, bundle_encoded)
    {:noreply, state}
  end

end