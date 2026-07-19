defmodule PTAX do
  @moduledoc """
  Converts between currencies using the Brazilian Central Bank's PTAX rates.

  Each conversion uses the published quote that matches its direction: the bid
  rate for the currency being sold into BRL, and the ask rate for the currency
  being bought with BRL. A cross conversion between two non-BRL currencies sells
  the source at its bid and buys the target at its ask.
  """

  alias PTAX.Retriever

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
  def exchange(%Money{} = money, to_currency) do
    with {:ok, to_currency} <- Money.validate_currency(to_currency),
         {:ok, rates} <- latest_rates(money.currency, to_currency),
         {:ok, money} <- Money.to_currency(money, to_currency, rates) do
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
  def exchange!(%Money{} = money, to_currency) do
    case exchange(money, to_currency) do
      {:ok, money} -> money
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using PTAX rates for the given date.

  Returns `{:ok, Money.t()}` on success, or `{:error, reason}` if the rates
  are unavailable or the currency is not supported.

  ## Examples

      iex> PTAX.exchange(Money.new(:GBP, "50"), :BRL, ~D[2026-05-15])
      {:ok, Money.new(:BRL, "337.60")}

      iex> PTAX.exchange(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
      {:error, {Money.ExchangeRateError, "no exchange rates available for 2025-12-25"}}

  """
  @spec exchange(Money.t(), Money.currency_reference(), Date.t()) ::
          {:ok, Money.t()} | {:error, {Exception.t(), String.t()}}
  def exchange(%Money{} = money, to_currency, date) do
    with {:ok, to_currency} <- Money.validate_currency(to_currency),
         {:ok, rates} <- historic_rates(money.currency, to_currency, date),
         {:ok, money} <- Money.to_currency(money, to_currency, rates) do
      {:ok, Money.round(money, currency_digits: :cash)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using PTAX rates for the given date.

  Raises if the rates are unavailable or the currency is not supported.

  ## Examples

      iex> PTAX.exchange!(Money.new(:GBP, "50"), :BRL, ~D[2026-05-15])
      Money.new(:BRL, "337.60")

      iex> PTAX.exchange!(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
      ** (Money.ExchangeRateError) no exchange rates available for 2025-12-25

  """
  @spec exchange!(Money.t(), Money.currency_reference(), Date.t()) :: Money.t()
  def exchange!(%Money{} = money, to_currency, date) do
    case exchange(money, to_currency, date) do
      {:ok, money} -> money
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp latest_rates(from, to) do
    with {:ok, bid} <- Retriever.latest_rates(:bid),
         {:ok, ask} <- Retriever.latest_rates(:ask) do
      {:ok, %{from => Map.get(bid, from), to => Map.get(ask, to)}}
    end
  end

  defp historic_rates(from, to, date) do
    with {:ok, bid} <- Retriever.historic_rates(:bid, date),
         {:ok, ask} <- Retriever.historic_rates(:ask, date) do
      {:ok, %{from => Map.get(bid, from), to => Map.get(ask, to)}}
    end
  end
end
