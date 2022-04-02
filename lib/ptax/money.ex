defmodule PTAX.Money do
  @moduledoc "Defines a `Money` structure for working with currencies."

  use TypedStruct
  import Decimal, only: [is_decimal: 1]
  alias PTAX.Money.Pair

  @type currency :: atom()
  @type amount :: Decimal.t()

  typedstruct enforce: true do
    field :amount, amount
    field :currency, currency
  end

  @doc """
  Create a new `Money` given the amount and currency.

  ## Examples:

      iex> PTAX.Money.new(10)
      %PTAX.Money{amount: Decimal.new(10), currency: :BRL}

      iex> PTAX.Money.new("12.75", :USD)
      %PTAX.Money{amount: Decimal.new("12.75"), currency: :USD}

      iex> PTAX.Money.new(123, :GBP)
      %PTAX.Money{amount: Decimal.new(123), currency: :GBP}
  """
  @spec new(amount :: any, currency) :: t
  def new(amount, currency \\ :BRL)

  def new(amount, currency) do
    struct!(__MODULE__, %{amount: to_amount(amount), currency: currency})
  end

  @doc """
  Exchange from a currency to another given the rate.

  ## Examples:

      iex> PTAX.Money.exchange(PTAX.Money.new(10, :USD), PTAX.Money.Pair.new(5, "5.5", :USD, :BRL))
      %PTAX.Money{amount: Decimal.new(50), currency: :BRL}

      iex> PTAX.Money.exchange(PTAX.Money.new(1, :USD), PTAX.Money.Pair.new("1.5", 2, :GBP, :USD))
      %PTAX.Money{amount: Decimal.new("0.5"), currency: :GBP}

      iex> PTAX.Money.exchange(PTAX.Money.new(115, :JPY), PTAX.Money.Pair.new("114.5", 115, :USD, :JPY))
      %PTAX.Money{amount: Decimal.new(1), currency: :USD}

      iex> PTAX.Money.exchange(PTAX.Money.new(1, :USD), PTAX.Money.Pair.new("114.5", 115, :USD, :JPY))
      %PTAX.Money{amount: Decimal.new("114.5"), currency: :JPY}
  """
  @spec exchange(money, pair :: Pair.t()) :: money when money: t

  def exchange(money, %{base_currency: currency, quoted_currency: currency}) do
    money
  end

  def exchange(%{currency: currency} = money, %{quoted_currency: currency} = pair) do
    money.amount
    |> Decimal.div(pair.amount.ask)
    |> new(pair.base_currency)
  end

  def exchange(%{currency: currency} = money, %{base_currency: currency} = pair) do
    money.amount
    |> Decimal.mult(pair.amount.bid)
    |> new(pair.quoted_currency)
  end

  @spec normalize(money) :: money when money: t
  def normalize(money) do
    money.amount
    |> Decimal.round(4)
    |> Decimal.normalize()
    |> new(money.currency)
  end

  @spec to_amount(value :: Decimal.decimal() | float) :: amount
  def to_amount(value) when is_decimal(value), do: value
  def to_amount(value) when is_float(value), do: Decimal.from_float(value)
  def to_amount(value) when is_integer(value) when is_binary(value), do: Decimal.new(value)

  defimpl Inspect do
    def inspect(%{amount: amount, currency: currency}, _opts) do
      "#Money<#{amount}, #{currency}>"
    end
  end
end
