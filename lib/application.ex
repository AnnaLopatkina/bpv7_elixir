defmodule Application do
  @moduledoc false

  def start(_type, _args) do
    children = [
      {Task, fn -> Server.accept(4040) end}
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
