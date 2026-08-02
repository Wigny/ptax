defmodule PTAX.Rates do
  @moduledoc """
  The source of the rates `PTAX` converts with.

  Every conversion reads its rate through this behaviour, resolved for the pair from the
  bulletin BCB published for the date.

  Each direction reads the side of the spread matching it, because BCB publishes a separate bid
  and ask for every currency.
  """

  @doc """
  Returns the rate converting `from_currency` into `to_currency` on `date`, or
  `{:error, exception}` if no rate is available for the pair.

  The rate is how many units of `to_currency` one unit of `from_currency` buys, and the rate for
  the opposite direction is not its reciprocal.
  """
  @callback rate(
              from_currency :: Localize.Currency.currency_code(),
              to_currency :: Localize.Currency.currency_code(),
              date :: Date.t()
            ) :: {:ok, Decimal.t()} | {:error, Exception.t()}

  @behaviour __MODULE__

  @impl true
  def rate(from_currency, to_currency, date) do
    with {:ok, quotes} <- PTAX.Quotes.fetch(date),
         {:ok, from_quotation} <- fetch_quotation(quotes, from_currency),
         {:ok, to_quotation} <- fetch_quotation(quotes, to_currency) do
      {:ok, rate({from_currency, from_quotation}, {to_currency, to_quotation})}
    end
  end

  defp fetch_quotation(quotes, currency) do
    case quotes do
      %{^currency => quotation} -> {:ok, quotation}
      _quotes -> {:error, PTAX.CurrencyNotQuotedError.exception(currency: currency)}
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
