defmodule Bpv7.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Task.Supervisor, name: Bpv7.Server.TaskSupervisor},
      {Task, fn -> Bpv7.Server.accept(port) end}
    ]

    opts = [strategy: :one_for_one, name: Bpv7.Server.Supervisor]
    Supervisor.start_link(children, opts)

    Bpv7.ConnManager.start([])
  end

  @doc """
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Bpv7.Server.TaskSupervisor},
      {Task, fn -> Bpv7.Server.accept(4040) end}
    ]

    opts = [strategy: :one_for_one, name: Bpv7.Server.Supervisor]
    Supervisor.start_link(children, opts)

    Bpv7.ConnManager.start([])
  end
end
  """

end