defmodule Bpv7.Config_server do
  require Logger
  @moduledoc """
  The configuration Server holds connection information like eid, host, port, begin_time, end_time
  in order to send a Bundle
  """

  @doc """
  Listens to a port until the port is available and it gets hold of the socket

  ## Parameters
  - port: Port to connect to
  """
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting config on port #{port}")
    loop_acceptor(socket)
  end

  @doc """
  Waits for a client connection on that port and accepts it

  ## Parameters

  - socket:
  """
  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Bpv7.CLA_tcp.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    Logger.info("config Session Connected")
    loop_acceptor(socket)
  end

  @doc """
  Reads the client request

  ## Parameters

  - socket:
  """
  defp serve(socket) do
    read_line(socket)

    serve(socket)
  end


  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data = String.trim(data, "\r\n")
    data = String.split(data, ",", parts: 5)
    case DateTime.from_iso8601(Enum.at(data,3)) do
      :ok, _, _ -> Logger.info("begin_time ok")
        begin_time = DateTime.from_iso8601(Enum.at(data,3))
           case  DateTime.from_iso8601(Enum.at(data,4)) do
                :ok, _, _ -> Logger.info("end_time ok")
                     end_time = DateTime.from_iso8601(Enum.at(data,4))
                     eid = Enum.at(data, 0)
                     host = to_charlist(Enum.at(data,1))
                     port = String.to_integer(Enum.at(data,2))
                     add_node = Bpv7.BPA.add_tcp_node(eid, host, port, begin_time, end_time)
                     case add_node do
                        :ok -> Logger.info("Connection: #{host} on port #{port},
                                              eid: #{eid},
                                              begin time: #{begin_time},
                                              end time: #{end_time}")
                         _ -> Logger.info("error")
                     end
                _ -> Logger.info("end_time incorrect format")
           end
      _ -> Logger.info("begin_time incorrect format")
    end

  end



end
