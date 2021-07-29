defmodule Bpv7.BPA do
  use Agent
  use GenServer
  require Logger
  @moduledoc """
  The Bundle Protocol Agent (BPA) holds the connection information for the EIDs.
  It saves the connection Protocol, host, port and the times of availability for every EID and gives the possibility to
  receive this information from the BPA.

  Furthermore it does the scheduling of packages and delays them until a suitable node is available.
  """

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
    schedule_time = Bpv7.Helpers.get_schedule_time(avail_begin)
    Process.send_after(__MODULE__, {:connect_tcp, eid}, schedule_time)
    :ok
  end

  def get_connection_method(eid) do
    case get_node(eid) do
      {method, _, _, _, _} -> method
      :not_found -> :not_found
    end
  end

  @doc """
  Returns a tupel with `hostname` and `port` for the connection to the given `eid`.

  If no suitable configuration is found `:not_found` will be returned.
  """
  def get_tcp_conn_details(eid) do
    case get_node(eid) do
      {:tcp, host, port, _, _ } -> {host, port}
      :not_found -> :not_found
    end
  end

  @doc """
  Returns a tupel with the Availability of the given `eid`.
  The first value is the Begin and the second the end of the availability.

  If no suitable configuration is found `:not_found` will be returned.
  """
  def get_availability(eid) do
    case get_node(eid) do
      {_, _, _, avail_begin, avail_end} -> {avail_begin, avail_end}
      :not_found -> :not_found
    end
  end

  defp ongoing?(end_time) do
    current_time = DateTime.utc_now()
    case DateTime.compare(end_time, current_time) do
     :gt -> true
     :eq -> false
     :lt -> false
    end
  end

  defp get_node(eid) do
    case Agent.get(:nodes, &Map.get(&1, eid)) do
      {method, host, port, avail_begin, avail_end} ->
        if ongoing?(avail_end) do
          {method, host, port, avail_begin, avail_end}
        else
          remove_node(eid)
          :not_found
        end
      nil ->
        :not_found
    end
  end

  defp remove_node(eid) do
    {:tcp, host, port, _, _} = Agent.get_and_update(:nodes, &Map.pop(&1, eid))
    :ok = Bpv7.ConnManager.disconnect(host, port)
    Logger.info("Entry of #{eid} was removed because it is outdated.")
    :ok
  end

  @doc """
  Schedules a Bundle for the forwarding to a foreign node.
  The specific send time is retrieved from the configuration.

  If no configuration is given the scheduling is retried every 5 seconds.
  """
  def schedule_bundle(bundle, eid) do
    {schedule_task, schedule_time} =
    case get_availability(eid) do
      {avail_begin, _avail_end} ->
        schedule_time = Bpv7.Helpers.get_schedule_time(avail_begin)
        {:send, schedule_time}
      :not_found ->
        Logger.info("No configuration found for #{eid}. Trying again in 5 seconds.")
        {:schedule, 5000}
    end
    Process.send_after(__MODULE__,{schedule_task, bundle, eid}, schedule_time)
    :ok
  end

  @doc """
  Callback for Events which should happen later.
  There are different Functions that can be distinguished by the Atom at the beginning of the argument tuple.
  The available Function will be described below.

  `{:schedule, bundle, eid}`
  Callback to retry the Scheduling of the Bundle if there was no suitable configuration at the previous attempt.

  `{:send, bundle, eid}`
  Callback for sending the bundle when the configured Availability time is reached.
  """
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

  def handle_info({:connect_tcp, eid}, state) do
    {:tcp, host, port, _, _} = get_node(eid)
    unless Bpv7.ConnManager.check_connection?(host, port) do
      Bpv7.ConnManager.connect(host, port)
    end
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Outgoing connection to peer closed.")
    {:noreply, state}
  end

  def handle_info(:not_found, state) do
    Logger.info("Peer Node ist not reachable (anymore).")
    {:noreply, state}
  end
end