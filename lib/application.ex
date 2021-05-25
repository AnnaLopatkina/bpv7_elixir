defmodule Application do
  @moduledoc false

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")
    children = [
      {Task, fn -> Server.accept(port) end}
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
