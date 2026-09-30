defmodule PTAX.Rates do
  @moduledoc """
  The source of the rates `PTAX` converts with.

  Every conversion reads its rate through this behaviour, resolved for the pair from the
  bulletin BCB published for the given date, or from the latest one.

  A rate is how many units of the target currency one unit of the source currency buys, and the
  rate for the opposite direction is not its reciprocal.

  Each direction reads the side of the spread matching it, because BCB publishes a separate bid
  and ask for every currency.
  """

  @doc """
  Returns the rate converting `from_currency` into `to_currency` from the latest published
  bulletin, or `{:error, exception}` if no rate is available for the pair.
  """
  @callback rate(
              from_currency :: Localize.Currency.currency_code(),
              to_currency :: Localize.Currency.currency_code()
            ) :: {:ok, Decimal.t()} | {:error, Exception.t()}

  @doc """
  Returns the rate converting `from_currency` into `to_currency` on `date`, or
  `{:error, exception}` if no rate is available for the pair.
  """
  @callback rate(
              from_currency :: Localize.Currency.currency_code(),
              to_currency :: Localize.Currency.currency_code(),
              date :: Date.t()
            ) :: {:ok, Decimal.t()} | {:error, Exception.t()}

  @behaviour __MODULE__

  @impl true
  def rate(from_currency, to_currency) do
    now = DateTime.now!("America/Sao_Paulo", Tz.TimeZoneDatabase)
    [latest_date, previous_date] = Enum.take(PTAX.Quotes.publish_dates(now), 2)

    with {:error, %PTAX.QuotesNotFoundError{}} <- rate(from_currency, to_currency, latest_date),
         {:error, %PTAX.QuotesNotFoundError{}} <- rate(from_currency, to_currency, previous_date),
         do: {:error, %PTAX.LatestQuotesNotFoundError{}}
  end

  @impl true
  def rate(from_currency, to_currency, date) do
    with {:ok, quotes} <- PTAX.Quotes.fetch(date),
         {:ok, from_quotation} <- fetch_quotation(quotes, from_currency),
         {:ok, to_quotation} <- fetch_quotation(quotes, to_currency) do
      {:ok, quoted_rate({from_currency, from_quotation}, {to_currency, to_quotation})}
    end
  end

  defp fetch_quotation(_quotes, :BRL), do: {:ok, nil}

  defp fetch_quotation(quotes, currency) do
    case quotes do
      %{^currency => quotation} -> {:ok, quotation}
      _quotes -> {:error, PTAX.CurrencyNotQuotedError.exception(currency: currency)}
    end
  end

  defp quoted_rate({currency, _base}, {currency, _counter}), do: Decimal.new(1)
  defp quoted_rate({:BRL, nil}, {_to, counter}), do: Decimal.div(1, counter.ask)
  defp quoted_rate({_from, base}, {:BRL, nil}), do: base.bid

  defp quoted_rate({:USD, _base}, {_to, %{type: :direct} = counter}),
    do: Decimal.div(1, counter.ask_parity)

  defp quoted_rate({:USD, _base}, {_to, %{type: :indirect} = counter}), do: counter.bid_parity
  defp quoted_rate({_from, %{type: :direct} = base}, {:USD, _counter}), do: base.bid_parity

  defp quoted_rate({_from, %{type: :indirect} = base}, {:USD, _counter}),
    do: Decimal.div(1, base.ask_parity)

  # BCB defines the cross rate on its own terms rather than composing two USD conversions, so
  # the source reads its bid parity even where that is the customer-favorable side.
  defp quoted_rate({_from, %{type: type} = base}, {_to, %{type: type} = counter}),
    do: Decimal.div(parity(base, base.bid_parity), parity(counter, counter.ask_parity))

  defp quoted_rate({_from, base}, {_to, counter}),
    do: Decimal.div(parity(base, base.bid_parity), parity(counter, counter.bid_parity))

  defp parity(%{type: :direct}, value), do: value
  defp parity(%{type: :indirect}, value), do: Decimal.div(1, value)
end
