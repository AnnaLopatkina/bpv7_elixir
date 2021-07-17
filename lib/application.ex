defmodule Bpv7.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")
    children = [
      {Task.Supervisor, name: Bpv7.Server.TaskSupervisor},
      {Task, fn -> Bpv7.Server.accept(port) end},
      Bpv7.BPA
    ]

    opts = [strategy: :one_for_one, name: Bpv7.Server.Supervisor]
    Supervisor.start_link(children, opts)

    Bpv7.ConnManager.start([])

  end
end
