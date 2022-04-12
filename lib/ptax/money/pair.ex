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

      iex> PTAX.Money.Pair.new(2, 2.1, :GBP, :USD)
      %PTAX.Money.Pair{amount: %{bid: Decimal.new(2), ask: Decimal.new("2.1")}, base_currency: :GBP, quoted_currency: :USD}
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
        bid: Money.to_amount(bid, 7),
        ask: Money.to_amount(ask, 7)
      },
      base_currency: base_currency,
      quoted_currency: quoted_currency
    })
  end

  @doc """
  TODO

  ## Examples:

      iex> PTAX.Money.Pair.equate(PTAX.Money.Pair.new(6.5673, 6.5691, :USD, :DKK), PTAX.Money.Pair.new(8.8365, 8.8395, :USD, :NOK))
      PTAX.Money.Pair.new(1.3459869, 0.7429493, :DKK, :NOK)
      iex> PTAX.Money.Pair.equate(PTAX.Money.Pair.new(8.8365, 8.8395, :USD, :NOK), PTAX.Money.Pair.new(6.5673, 6.5691, :USD, :DKK))
      PTAX.Money.Pair.new(0.7434052, 1.3451614, :NOK, :DKK)

      iex> PTAX.Money.Pair.equate(PTAX.Money.Pair.new(1.2813, 1.2815, :USD, :CAD), PTAX.Money.Pair.new(0.7232, 0.7236, :AUD, :USD))
      PTAX.Money.Pair.new(1.0791722, 0.9266362, :CAD, :AUD)
      iex> PTAX.Money.Pair.equate(PTAX.Money.Pair.new(0.7232, 0.7236, :AUD, :USD), PTAX.Money.Pair.new(1.2813, 1.2815, :USD, :CAD))
      PTAX.Money.Pair.new(0.9266362, 1.0791722, :AUD, :CAD)
  """

  def equate(%{base_currency: currency, quoted_currency: currency}, pair2) do
    pair2
  end

  def equate(pair1, %{base_currency: currency, quoted_currency: currency}) do
    pair1
  end

  def equate(%{base_currency: currency} = pair1, %{base_currency: currency} = pair2) do
    bid = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.mult(pair2.amount.ask)
    ask = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.div(pair2.amount.ask)

    new(bid, ask, pair1.quoted_currency, pair2.quoted_currency)
  end

  def equate(%{quoted_currency: currency} = pair1, %{quoted_currency: currency} = pair2) do
    bid = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.div(pair2.amount.ask)
    ask = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.mult(pair2.amount.ask)

    new(bid, ask, pair1.base_currency, pair2.base_currency)
  end

  def equate(%{base_currency: :USD} = pair1, pair2) do
    bid = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.div(pair2.amount.bid)
    ask = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.mult(pair2.amount.bid)

    new(bid, ask, pair1.quoted_currency, pair2.base_currency)
  end

  def equate(pair1, %{base_currency: :USD} = pair2) do
    bid = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.mult(pair2.amount.bid)
    ask = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.div(pair2.amount.bid)

    new(bid, ask, pair1.base_currency, pair2.quoted_currency)
  end

  defimpl Inspect do
    def inspect(pair, _opts) do
      "#Money.Pair<#{pair.amount.bid}/#{pair.amount.ask}, #{pair.base_currency}/#{pair.quoted_currency}>"
    end
  end
end
