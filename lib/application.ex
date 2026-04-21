defmodule Shorty.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Shorty.Store,
      {Shorty.Server, 4000}
    ]

    opts = [strategy: :one_for_one, name: Shorty.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
