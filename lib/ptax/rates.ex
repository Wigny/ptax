defmodule PTAX.Rates do
  @moduledoc """
  The contract `PTAX` reads BCB's rates through.

  Set `:ptax, :rates` to a stub implementing it so a test suite serves known rates instead of
  reaching BCB:

      config :ptax, rates: MyApp.RatesMock

  Both callbacks return a rates map keyed by currency, each value the number of units of that
  currency per BRL.
  """

  @typedoc "Which PTAX closing quote to read: the bid or the ask."
  @type quote_side :: :bid | :ask

  @doc "Returns the latest known rates for the given quote side."
  @callback latest_rates(quote_side) :: {:ok, Money.ExchangeRates.t()} | {:error, term}

  @doc "Returns the rates for the given quote side on `date`."
  @callback historic_rates(quote_side, Date.t()) ::
              {:ok, Money.ExchangeRates.t()} | {:error, term}
end
