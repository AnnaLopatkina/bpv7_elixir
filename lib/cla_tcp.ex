defmodule Bpv7.CLA_tcp do
  require Logger
  @moduledoc """
  A Convergence Layer Adapter (CLA) for TCP Connections.
  It accepts all incoming TCP connections on the port which is specified by starting the CLA with the `accept` function.
  Every well CBOR formatted Bytestring will be forwarded to the Bundle Manager.
  It is possible to have several open connections which receive packeges in parallel.
  """


  @doc """
  Starts accepting connections on given `port`
  """
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
    {:ok, {address, port}} = :inet.peername(client)
    address = address |> Tuple.to_list |> Enum.join(".")
    Logger.info("Incoming Connection from #{address}:#{port}.")
    {:ok, pid} = Task.Supervisor.start_child(Bpv7.CLA_tcp.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    case read(socket, nil) do
      {:ok, bundle} ->
        forward(bundle)
        serve(socket)
      :error ->
        nil
    end
  end

  defp read(socket, parent) do
    response = case :gen_tcp.recv(socket, 0) do
      {:ok, chunk} ->
        data =
          case parent do
            nil -> chunk
            _ -> parent <> chunk
          end
        data = try do
          {:ok, plain_data, ""} = CBOR.decode(data)
          plain_data
        rescue
          MatchError -> read(socket, data)
        end
        {:ok, data}
      {:error, :closed} ->
        Logger.info("Connection closed.")
        :error
      {:error, error} ->
        Logger.info("Connection closed with error #{error}")
        :error
    end
    response
  end

  defp forward(bundle) do
    {:ok,bundle} = Map.fetch(bundle,:value)
    {:ok, bundle, ""} = CBOR.decode(bundle)
    hex_data = Base.encode16(<<159>> <> Bpv7.Bundle_Manager.bundleblock_binary(bundle) <> <<255>>)
    Logger.info("Bundle Received: #{hex_data}")
    :ok = Bpv7.Bundle_Manager.forward_bundle(bundle)
  end
end
