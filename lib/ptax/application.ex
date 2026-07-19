defmodule PTAX.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: PTAX.Registry},
      {PTAX.Retriever, :bid},
      {PTAX.Retriever, :ask}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PTAX.Supervisor)
  end
end
