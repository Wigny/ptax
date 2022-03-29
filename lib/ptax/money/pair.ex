defmodule PTAX.Money.Pair do
  @moduledoc "Defines a `Currency Pair` structure."

  use TypedStruct
  import Decimal, only: [is_decimal: 1]
  alias PTAX.Money

  typedstruct enforce: true do
    field :amount, Decimal.t()
    field :base_currency, Money.currency()
    field :quoted_currency, Money.currency()
  end

  @doc """
  Create a new currency pair.

  ## Examples:

      iex> PTAX.Money.Pair.new(2, :GBP, :USD)
      %PTAX.Money.Pair{amount: Decimal.new(2), base_currency: :GBP, quoted_currency: :USD}
  """
  @spec new(amount :: any, currency, currency) :: t when currency: Money.currency()
  def new(amount, base_currency, quoted_currency) when is_decimal(amount) do
    struct!(__MODULE__, %{
      amount: amount,
      base_currency: base_currency,
      quoted_currency: quoted_currency
    })
  end

  def new(amount, base_currency, quoted_currency) when is_float(amount) do
    amount |> Decimal.from_float() |> new(base_currency, quoted_currency)
  end

  def new(amount, base_currency, quoted_currency) do
    amount |> Decimal.new() |> new(base_currency, quoted_currency)
  end

  defimpl Inspect do
    def inspect(pair, _opts) do
      "#Money.Pair<#{pair.amount}, #{pair.base_currency}/#{pair.quoted_currency}>"
    end
  end
end
