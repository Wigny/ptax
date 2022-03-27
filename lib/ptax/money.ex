defmodule PTAX.Money do
  @moduledoc "Defines a `Money` structure for working with currencies."

  use TypedStruct
  import Decimal, only: [is_decimal: 1]
  alias PTAX.Error

  @type currency :: atom()

  typedstruct enforce: true do
    field :amount, Decimal.t()
    field :currency, currency
  end

  @doc """
  Create a new `Money` given the amount and currency.

  Examples:

      iex> PTAX.Money.new(10)
      %PTAX.Money{amount: Decimal.new(10), currency: :BRL}

      iex> PTAX.Money.new(12.75, :USD)
      %PTAX.Money{amount: Decimal.new("12.75"), currency: :USD}

      iex> PTAX.Money.new("123", :GBP)
      %PTAX.Money{amount: Decimal.new(123), currency: :GBP}
  """
  @spec new(amount :: any, currency) :: t
  def new(amount, currency \\ :BRL)

  def new(amount, currency) when is_decimal(amount) do
    struct!(__MODULE__, %{amount: amount, currency: currency})
  end

  def new(amount, currency) when is_float(amount) do
    amount |> Decimal.from_float() |> new(currency)
  end

  def new(amount, currency) do
    amount |> Decimal.new() |> new(currency)
  end

  @doc """
  Exchange from a currency to another given the rate.

  Examples:

      iex> PTAX.Money.exchange!(PTAX.Money.new(12.75, :USD), to: :BRL, rate: PTAX.Money.new(5, :BRL))
      %PTAX.Money{amount: Decimal.new("63.75"), currency: :BRL}

      iex> PTAX.Money.exchange!(PTAX.Money.new(10), to: :USD, rate: PTAX.Money.new(5, :BRL))
      %PTAX.Money{amount: Decimal.new(2), currency: :USD}

      iex> PTAX.Money.exchange!(PTAX.Money.new(10), to: :USD, rate: PTAX.Money.new("0.2", :USD))
      %PTAX.Money{amount: Decimal.new(2), currency: :USD}

      iex> PTAX.Money.exchange!(PTAX.Money.new("123", :GBP), to: :GBP, rate: PTAX.Money.new("1", :GBP))
      ** (PTAX.Error) Cannot exchange to the same currency!

      iex> PTAX.Money.exchange!(PTAX.Money.new(1, :USD), to: :GBP, rate: PTAX.Money.new(2, :USD))
      %PTAX.Money{amount: Decimal.new("0.5"), currency: :GBP}
  """
  @spec exchange!(money, to: currency, rate: money) :: money when money: t
  def exchange!(%{currency: currency}, to: currency, rate: _rate) do
    raise Error.new(message: "Cannot exchange to the same currency!")
  end

  def exchange!(%{currency: currency} = money, to: to, rate: %{currency: currency} = rate) do
    money.amount
    |> Decimal.div(rate.amount)
    |> Decimal.round(4, :up)
    |> Decimal.normalize()
    |> new(to)
  end

  def exchange!(money, to: to, rate: %{currency: to} = rate) do
    money.amount
    |> Decimal.mult(rate.amount)
    |> Decimal.round(4, :up)
    |> Decimal.normalize()
    |> new(to)
  end

  defimpl Inspect do
    def inspect(%{amount: amount, currency: currency}, _opts) do
      "#Money<#{amount}, #{inspect(currency)}>"
    end
  end
end
