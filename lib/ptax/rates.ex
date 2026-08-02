defmodule PTAX.Rates do
  @moduledoc """
  The rates BCB's bulletin for a date implies, in the shape `ex_money` takes them.

  The rates are relative to the base currency: each value is how many units of that currency one
  unit of the base currency buys, and the base currency itself maps to `1`. A map built for one
  base currency cannot be reused for another, because PTAX publishes a separate bid and ask for
  every currency and the two directions of a pair are not reciprocal.
  """

  @doc "Returns the PTAX rates on `date`, relative to `base_currency`."
  @callback rates(Localize.Currency.currency_code(), Date.t()) ::
              {:ok, Money.ExchangeRates.t()} | {:error, Exception.t()}

  @behaviour __MODULE__

  @impl true
  def rates(base_currency, date) do
    with {:ok, quotes} <- PTAX.Quotes.fetch(date) do
      rates =
        for {currency, quotation} <- quotes,
            base_quotation = quotes[base_currency],
            rate = rate({base_currency, base_quotation}, {currency, quotation}),
            into: %{},
            do: {currency, rate}

      {:ok, rates}
    end
  end

  defp rate({currency, _base}, {currency, _counter}), do: Decimal.new(1)
  defp rate({:BRL, %{type: :base}}, {_to, counter}), do: Decimal.div(1, counter.ask)
  defp rate({_from, base}, {:BRL, %{type: :base}}), do: base.bid

  defp rate({:USD, _base}, {_to, %{type: :direct} = counter}),
    do: Decimal.div(1, counter.ask_parity)

  defp rate({:USD, _base}, {_to, %{type: :indirect} = counter}), do: counter.bid_parity
  defp rate({_from, %{type: :direct} = base}, {:USD, _counter}), do: base.bid_parity

  defp rate({_from, %{type: :indirect} = base}, {:USD, _counter}),
    do: Decimal.div(1, base.ask_parity)

  # BCB defines the cross rate on its own terms rather than composing two USD conversions, so
  # the source reads its bid parity even where that is the customer-favorable side.
  defp rate({_from, %{type: type} = base}, {_to, %{type: type} = counter}),
    do: Decimal.div(parity(base, base.bid_parity), parity(counter, counter.ask_parity))

  defp rate({_from, base}, {_to, counter}),
    do: Decimal.div(parity(base, base.bid_parity), parity(counter, counter.bid_parity))

  defp parity(%{type: :direct}, value), do: value
  defp parity(%{type: :indirect}, value), do: Decimal.div(1, value)
end
