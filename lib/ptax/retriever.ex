defmodule PTAX.Retriever do
  @moduledoc """
  PTAX's named `ex_money` exchange-rate retriever.

  Started automatically with the `:ptax` application and isolated from
  `ex_money`'s default retriever. Address it directly to reach `ex_money`'s
  exchange-rate functions with PTAX data:

      Money.ExchangeRates.Retriever.latest_rates(PTAX.Retriever)
      Money.ExchangeRates.Retriever.historic_rates(PTAX.Retriever, ~D[2026-05-15])
  """

  @doc false
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(_opts) do
    config = %{
      Money.ExchangeRates.default_config()
      | api_module: PTAX.ExchangeRates,
        cache_module: PTAX.ExchangeRates.Cache
    }

    Supervisor.child_spec(
      {Money.ExchangeRates.Retriever, name: __MODULE__, config: config},
      id: __MODULE__
    )
  end
end
