defmodule PTAX.Money.Pair do
  @moduledoc "Defines a `Currency Pair` structure."

  use TypedStruct
  alias PTAX.Money

  defguardp is_type_a(pair) when pair.base_currency == :USD and pair.quoted_currency != :USD
  defguardp is_type_b(pair) when pair.base_currency != :USD and pair.quoted_currency == :USD

  typedstruct enforce: true do
    field :amount, %{ask: Money.amount(), bid: Money.amount()}
    field :base_currency, Money.currency()
    field :quoted_currency, Money.currency()
  end

  @doc """
  Create a new currency pair.

  ## Examples:

      iex> PTAX.Money.Pair.new(2, 2.1, :GBP, :USD)
      %PTAX.Money.Pair{amount: %{bid: PTAX.Money.to_amount(2), ask: PTAX.Money.to_amount("2.1")}, base_currency: :GBP, quoted_currency: :USD}
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
  Combines two currency pairs, based on their common currency

  ## Examples:

      # Type A / Type A
      iex> PTAX.Money.Pair.combine(PTAX.Money.Pair.new(6.5673, 6.5691, :USD, :DKK), PTAX.Money.Pair.new(8.8365, 8.8395, :USD, :NOK))
      PTAX.Money.Pair.new(1.3459869, 1.3451614, :DKK, :NOK)

      # Type A / Type B
      iex> PTAX.Money.Pair.combine(PTAX.Money.Pair.new(1.2813, 1.2815, :USD, :CAD), PTAX.Money.Pair.new(0.7232, 0.7236, :AUD, :USD))
      PTAX.Money.Pair.new(1.0791722, 1.0791722, :CAD, :AUD)

      # Type B / Type A
      iex> PTAX.Money.Pair.combine(PTAX.Money.Pair.new(1.3402, 1.3406, :GBP, :USD), PTAX.Money.Pair.new(0.9185, 0.9192, :USD, :CHF))
      PTAX.Money.Pair.new(1.2309737, 1.2309737, :GBP, :CHF)

      # Type B / Type B
      iex> PTAX.Money.Pair.combine(PTAX.Money.Pair.new(1.3402, 1.3406, :GBP, :USD), PTAX.Money.Pair.new(1.1319, 1.1323, :EUR, :USD))
      PTAX.Money.Pair.new(1.1836086, 1.1843802, :GBP, :EUR)
  """

  @spec combine(pair, pair) :: pair when pair: t

  def combine(%{base_currency: currency, quoted_currency: currency}, pair2) do
    pair2
  end

  def combine(pair1, %{base_currency: currency, quoted_currency: currency}) do
    pair1
  end

  def combine(pair1, pair2) when is_type_a(pair1) and is_type_a(pair2) do
    bid = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.mult(pair2.amount.ask)
    ask = 1 |> Decimal.div(pair1.amount.ask) |> Decimal.mult(pair2.amount.bid)

    new(bid, ask, pair1.quoted_currency, pair2.quoted_currency)
  end

  def combine(pair1, pair2) when is_type_b(pair1) and is_type_b(pair2) do
    bid = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.div(pair2.amount.ask)
    ask = 1 |> Decimal.mult(pair1.amount.ask) |> Decimal.div(pair2.amount.bid)

    new(bid, ask, pair1.base_currency, pair2.base_currency)
  end

  def combine(pair1, pair2) when is_type_a(pair1) and is_type_b(pair2) do
    amount = 1 |> Decimal.div(pair1.amount.bid) |> Decimal.div(pair2.amount.bid)

    new(amount, amount, pair1.quoted_currency, pair2.base_currency)
  end

  def combine(pair1, pair2) when is_type_b(pair1) and is_type_a(pair2) do
    amount = 1 |> Decimal.mult(pair1.amount.bid) |> Decimal.mult(pair2.amount.bid)

    new(amount, amount, pair1.base_currency, pair2.quoted_currency)
  end

  defimpl Inspect do
    def inspect(pair, _opts) do
      "#Money.Pair<#{pair.amount.bid}/#{pair.amount.ask}, #{pair.base_currency}/#{pair.quoted_currency}>"
    end
  end
end
