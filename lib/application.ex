defmodule Bpv7.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")
    children = [
      {Task.Supervisor, name: Bpv7.CLA_tcp.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Bpv7.CLA_tcp.accept(port) end}, id: :Bpv7CLAtcp),
      Supervisor.child_spec({Task, fn -> Bpv7.Config_server.accept(4041) end}, id: :Bpv7ConfigServer),
      Bpv7.BPA
    ]

    opts = [strategy: :one_for_one, name: Bpv7.CLA_tcp.Supervisor]
    Supervisor.start_link(children, opts)

    Bpv7.ConnManager.start([])

  end
end
