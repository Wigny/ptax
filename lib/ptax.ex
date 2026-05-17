defmodule PTAX do
  @moduledoc """
  Converts between currencies using the Brazilian Central Bank's PTAX rates.

  Rates are computed as the mid-point between BCB's closing bid and ask quotes
  for each currency pair.
  """

  @doc """
  Exchanges a `Money` amount to the given currency using the latest known PTAX rates.

  Returns `{:ok, Money.t()}` on success, or `{:error, reason}` if the rates
  are unavailable or the currency is not supported.

  ## Examples

      iex> {:ok, %Money{}} = PTAX.exchange(Money.new!(:USD, "100"), :BRL)

  """
  @spec exchange(Money.t(), Money.currency_reference()) ::
          {:ok, Money.t()} | {:error, {module(), binary()}}
  def exchange(%Money{} = money, currency) do
    with {:ok, money} <- Money.to_currency(money, currency) do
      {:ok, Money.round(money, currency_digits: :cash)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using PTAX rates for the given date.

  Returns `{:ok, Money.t()}` on success, or `{:error, reason}` if the rates
  are unavailable or the currency is not supported.

  ## Examples

      iex> PTAX.exchange(Money.new!(:GBP, "50"), :BRL, ~D[2026-05-15])
      {:ok, Money.new!(:BRL, "337.63")}

  """
  @spec exchange(Money.t(), Money.currency_reference(), Date.t()) ::
          {:ok, Money.t()} | {:error, {module(), binary()}}
  def exchange(%Money{} = money, currency, date) do
    rates = Money.ExchangeRates.historic_rates(date)

    with {:ok, money} <- Money.to_currency(money, currency, rates) do
      {:ok, Money.round(money, currency_digits: :cash)}
    end
  end
end
