defmodule Schedule_Forwarding.Periodically do
  use GenServer
"""
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work(milliseconds) do
    Process.send_after(self(), :work, milliseconds) # In 2 hours
  end
"""
end