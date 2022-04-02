defmodule PTAX.Money.Pair do
  @moduledoc "Defines a `Currency Pair` structure."

  use TypedStruct
  alias PTAX.Money

  typedstruct enforce: true do
    field :amount, %{ask: Money.amount(), bid: Money.amount()}
    field :base_currency, Money.currency()
    field :quoted_currency, Money.currency()
  end

  @doc """
  Create a new currency pair.

  ## Examples:

      iex> PTAX.Money.Pair.new(2, :GBP, :USD)
      %PTAX.Money.Pair{amount: Decimal.new(2), base_currency: :GBP, quoted_currency: :USD}
  """
  @spec new(
          bid :: value,
          ask :: value,
          base_currency :: currency,
          quoted_currency :: currency
        ) :: t
        when currency: Money.currency(), value: Decimal.decimal() | float
  def new(bid, ask, base_currency, quoted_currency) do
    struct!(__MODULE__, %{
      amount: %{
        bid: Money.to_amount(bid),
        ask: Money.to_amount(ask)
      },
      base_currency: base_currency,
      quoted_currency: quoted_currency
    })
  end

  defimpl Inspect do
    def inspect(pair, _opts) do
      "#Money.Pair<#{pair.amount.bid}/#{pair.amount.ask}, #{pair.base_currency}/#{pair.quoted_currency}>"
    end
  end
end
