defmodule PTAX do
  @moduledoc """
  Converts between currencies using the Brazilian Central Bank's PTAX quotes.

  For each business day BCB publishes, per currency, a bid and an ask against BRL and against
  USD. A conversion always takes the side of the spread that matches its direction, and which
  pair of quotes it reads depends on the currencies involved: conversions with BRL on one side
  use the BRL quotes, conversions with USD on one side use the USD quotes, and conversions
  between two other currencies combine both currencies' USD quotes.

  That last case is BCB's own rule rather than two conversions through USD, so its result
  differs from converting via USD in two steps.
  """

  @doc """
  Exchanges a `Money` amount to the given currency using the latest published PTAX quotes.

  BCB publishes a bulletin only on business days, from 13h Brasília time, so the bulletin of the
  latest business day is used, or of the one before it if the latest is not out yet. Returns
  `{:error, exception}` if neither was published, or if the currency is not supported.

  ## Examples

      iex> {:ok, %Money{}} = PTAX.exchange(Money.new!(:USD, "100"), :BRL)

      iex> PTAX.exchange(Money.new!(:BRL, "100"), :XYZ)
      {:error, %Money.UnknownCurrencyError{message: "The currency :XYZ is not known."}}

  """
  @spec exchange(Money.t(), Money.currency_reference()) ::
          {:ok, Money.t()} | {:error, Exception.t()}
  def exchange(%Money{} = money, currency) do
    rates_module = Application.get_env(:ptax, :rates, PTAX.Rates)

    with {:ok, currency} <- parse_currency(currency),
         {:ok, rate} <- rates_module.rate(money.currency, currency) do
      {:ok, to_currency!(money, currency, rate)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using the latest published PTAX quotes.

  Raises if no bulletin was published for the latest two business days, or if the currency is not
  supported.

  ## Examples

      iex> %Money{} = PTAX.exchange!(Money.new!(:USD, "100"), :BRL)

      iex> PTAX.exchange!(Money.new!(:BRL, "100"), :XYZ)
      ** (Money.UnknownCurrencyError) The currency :XYZ is not known.

  """
  @spec exchange!(Money.t(), Money.currency_reference()) :: Money.t()
  def exchange!(%Money{} = money, currency) do
    case exchange(money, currency) do
      {:ok, money} -> money
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using the PTAX quotes for the given date.

  Returns `{:ok, Money.t()}` on success, or `{:error, exception}` if BCB published no bulletin for
  the date, or if the currency is not supported.

  ## Examples

      iex> PTAX.exchange(Money.new!(:GBP, "50"), :BRL, ~D[2026-07-31])
      {:ok, Money.new(:BRL, Decimal.new("341.8150000"))}

      iex> PTAX.exchange(Money.new!(:BRL, "100"), :ZWL, ~D[2026-07-31])
      {:error, %PTAX.CurrencyNotQuotedError{currency: :ZWL}}

  """
  @spec exchange(Money.t(), Money.currency_reference(), Date.t()) ::
          {:ok, Money.t()} | {:error, Exception.t()}
  def exchange(%Money{} = money, currency, %Date{} = date) do
    rates_module = Application.get_env(:ptax, :rates, PTAX.Rates)

    with {:ok, currency} <- parse_currency(currency),
         {:ok, rate} <- rates_module.rate(money.currency, currency, date) do
      {:ok, to_currency!(money, currency, rate)}
    end
  end

  @doc """
  Exchanges a `Money` amount to the given currency using the PTAX quotes for the given date.

  Raises if BCB published no bulletin for the date, or if the currency is not supported.

  ## Examples

      iex> PTAX.exchange!(Money.new!(:GBP, "50"), :BRL, ~D[2026-07-31])
      Money.new(:BRL, Decimal.new("341.8150000"))

      iex> PTAX.exchange!(Money.new!(:BRL, "100"), :ZWL, ~D[2026-07-31])
      ** (PTAX.CurrencyNotQuotedError) PTAX does not quote :ZWL

  """
  @spec exchange!(Money.t(), Money.currency_reference(), Date.t()) :: Money.t()
  def exchange!(%Money{} = money, currency, %Date{} = date) do
    case exchange(money, currency, date) do
      {:ok, money} -> money
      {:error, exception} -> raise exception
    end
  end

  defp parse_currency(currency) do
    case Money.validate_currency(currency) do
      {:ok, currency} -> {:ok, currency}
      {:error, {module, reason}} -> {:error, module.exception(reason)}
    end
  end

  defp to_currency!(money, currency, rate) do
    money
    |> Money.to_currency!(currency, %{money.currency => Decimal.new(1), currency => rate})
    |> Money.round(currency_digits: 7)
  end
end
