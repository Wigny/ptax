defmodule PTAX.Retriever do
  @moduledoc """
  PTAX's named `ex_money` exchange-rate retrievers.

  PTAX runs two isolated retrievers, one per quote side (`:bid` and `:ask`). They
  start automatically with the `:ptax` application and stay separate from
  `ex_money`'s default retriever. Each side returns an ordinary rates map, usable
  with any `ex_money` function that accepts one.
  """

  alias Money.ExchangeRates.Retriever

  @typedoc "Which PTAX closing quote to read: the bid or the ask."
  @type quote_side :: :bid | :ask

  @doc false
  @spec child_spec(quote_side) :: Supervisor.child_spec()
  def child_spec(quote_side) when quote_side in ~w(bid ask)a do
    config = %{
      Money.ExchangeRates.default_config()
      | api_module: PTAX.ExchangeRates,
        retriever_options: %{quote_side: quote_side}
    }

    Supervisor.child_spec({Retriever, name: name(quote_side), config: config}, id: quote_side)
  end

  defp name(quote_side), do: {:via, Registry, {PTAX.Registry, {__MODULE__, quote_side}}}

  @doc """
  Returns the latest known rates for the given quote side.
  """
  @spec latest_rates(quote_side) :: {:ok, Money.ExchangeRates.t()} | {:error, term}
  def latest_rates(quote_side), do: Retriever.latest_rates(name(quote_side))

  @doc """
  Returns the rates for the given quote side on `date`.
  """
  @spec historic_rates(quote_side, Date.t()) :: {:ok, Money.ExchangeRates.t()} | {:error, term}
  def historic_rates(quote_side, date), do: Retriever.historic_rates(name(quote_side), date)
end
