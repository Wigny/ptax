defmodule PTAX.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([PTAX.Retriever], strategy: :one_for_one, name: PTAX.Supervisor)
  end
end
