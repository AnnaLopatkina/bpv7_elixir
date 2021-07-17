defmodule Bpv7.Config_server do
  require Logger
  @moduledoc false

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting config on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Bpv7.Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    Logger.info("config Session Connected")
    loop_acceptor(socket)
  end

  defp serve(socket) do
    read_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data = String.trim(data, "\r\n")
    data = String.split(data, ",", parts: 5)
    {:ok, begin_time, 0} = DateTime.from_iso8601(Enum.at(data,3))
    {:ok, end_time, 0} = DateTime.from_iso8601(Enum.at(data,4))
    eid = Enum.at(data, 0)
    host = to_charlist(Enum.at(data,1))
    port = String.to_integer(Enum.at(data,2))
    Bpv7.BPA.add_tcp_node(eid, host, port, begin_time, end_time)
  end

end
