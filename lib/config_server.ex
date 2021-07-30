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

  # Waits for a client connection on that port and accepts it
  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Bpv7.CLA_tcp.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    Logger.info("config Session Connected")
    loop_acceptor(socket)
  end

  # Reads the client request
  defp serve(socket) do
    read_line(socket)

    serve(socket)
  end


  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    try do
      data = String.trim(data, "\r\n")
      data = String.split(data, ",", parts: 5)
      eid = Enum.at(data, 0)
      host = to_charlist(Enum.at(data,1))
      port = String.to_integer(Enum.at(data,2))
      with {:ok, begin_time, 0} <- DateTime.from_iso8601(Enum.at(data,3)),
           {:ok, end_time, 0} <- DateTime.from_iso8601(Enum.at(data,4))
      do
        Bpv7.BPA.add_tcp_node(eid, host, port, begin_time, end_time)
        Logger.info("Connection: #{host} on port #{port},
                       eid: #{eid},
                       begin time: #{begin_time},
                       end time: #{end_time}")
      else
        {:error, :invalid_format} -> Logger.info("Parsing Datetime failed because of invalid format")
        {:error, :missing_offset} -> Logger.info("Parsing Datetime failes because of invalid offset")
        {:error, :invalid_time}   -> Logger.info("Parsing Datetime failed because of invalid Time")
        {:error, :invalid_date}   -> Logger.info("Parsing Datetime failed because of invalid Date")
      end
    rescue
      ArgumentError -> Logger.info("Invalid Config String")
    end
  end
end
