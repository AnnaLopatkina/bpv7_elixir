defmodule Bpv7.Server do
  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Bpv7.Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    IO.puts "Connected"
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line(nil)
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket, parent) do
    {:ok, chunk} = :gen_tcp.recv(socket, 0)
    data =
      case parent do
        nil -> chunk
        _ -> parent <> chunk
      end
    data = try do
      {:ok, plain_data, ""} = CBOR.decode(data)
      plain_data
    rescue
      MatchError -> read_line(socket, data)
    end
    data
  end

  defp write_line(line, socket) do
    #:gen_tcp.send(socket, line)
    hex_data = Base.encode16(line)
    IO.puts(hex_data)
  end
end
