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

      iex> {:ok, %Money{}} = PTAX.exchange(Money.new(:USD, "100"), :BRL)

      iex> PTAX.exchange(Money.new(:BRL, "100"), :XYZ)
      {:error, {Money.UnknownCurrencyError, "The currency :XYZ is not known."}}

  """
  @spec exchange(Money.t(), Money.currency_reference()) ::
          {:ok, Money.t()} | {:error, {Exception.t(), String.t()}}
  def exchange(%Money{} = money, currency) do
    with {:ok, money} <- Money.to_currency(money, currency) do
      {:ok, Money.round(money, currency_digits: :cash)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using the latest known PTAX rates.

  Raises if the rates are unavailable or the currency is not supported.

  ## Examples

      iex> %Money{} = PTAX.exchange!(Money.new(:USD, "100"), :BRL)

      iex> PTAX.exchange!(Money.new(:BRL, "100"), :XYZ)
      ** (Money.UnknownCurrencyError) The currency :XYZ is not known.

  """
  @spec exchange!(Money.t(), Money.currency_reference()) :: Money.t()
  def exchange!(%Money{} = money, currency) do
    money
    |> Money.to_currency!(currency)
    |> Money.round(currency_digits: :cash)
  end

  @doc """
  Exchanges a `Money` amount to the given currency using PTAX rates for the given date.

  Returns `{:ok, Money.t()}` on success, or `{:error, reason}` if the rates
  are unavailable or the currency is not supported.

  ## Examples

      iex> PTAX.exchange(Money.new(:GBP, "50"), :BRL, ~D[2026-05-15])
      {:ok, Money.new(:BRL, "337.63")}

      iex> PTAX.exchange(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
      {:error, {Money.ExchangeRateError, "no exchange rates available for 2025-12-25"}}

  """
  @spec exchange(Money.t(), Money.currency_reference(), Date.t()) ::
          {:ok, Money.t()} | {:error, {Exception.t(), String.t()}}
  def exchange(%Money{} = money, currency, date) do
    rates = Money.ExchangeRates.historic_rates(date)

    with {:ok, money} <- Money.to_currency(money, currency, rates) do
      {:ok, Money.round(money, currency_digits: :cash)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using PTAX rates for the given date.

  Raises if the rates are unavailable or the currency is not supported.

  ## Examples

      iex> PTAX.exchange!(Money.new(:GBP, "50"), :BRL, ~D[2026-05-15])
      Money.new(:BRL, "337.63")

      iex> PTAX.exchange!(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
      ** (Money.ExchangeRateError) no exchange rates available for 2025-12-25

  """
  @spec exchange!(Money.t(), Money.currency_reference(), Date.t()) :: Money.t()
  def exchange!(%Money{} = money, currency, date) do
    rates = Money.ExchangeRates.historic_rates(date)

    money
    |> Money.to_currency!(currency, rates)
    |> Money.round(currency_digits: :cash)
  end
end
