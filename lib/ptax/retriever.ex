defmodule PTAX.Retriever do
  @moduledoc false

  @behaviour PTAX.Rates

  alias Money.ExchangeRates.Retriever

  @spec child_spec(PTAX.Rates.quote_side()) :: Supervisor.child_spec()
  def child_spec(quote_side) when quote_side in ~w(bid ask)a do
    config = %{
      Money.ExchangeRates.default_config()
      | api_module: PTAX.ExchangeRates,
        retriever_options: %{quote_side: quote_side},
        retrieve_every: to_timeout(hour: 1)
    }

    Supervisor.child_spec({Retriever, name: name(quote_side), config: config}, id: quote_side)
  end

  defp name(quote_side), do: {:via, Registry, {PTAX.Registry, {__MODULE__, quote_side}}}

  @impl true
  def latest_rates(quote_side), do: Retriever.latest_rates(name(quote_side))

  @impl true
  def historic_rates(quote_side, date), do: Retriever.historic_rates(name(quote_side), date)
end
