# PTAX

A currency converter backed by the Brazilian Central Bank (BCB) PTAX closing rates.

Rates are the mid-point between BCB's closing bid and ask quotes for each currency pair.

## Installation

```elixir
def deps do
  [
    {:ptax, "~> 2.0"}
  ]
end
```

## Configuration

PTAX integrates with `ex_money`'s exchange rate system. Add it to your config:

```elixir
# config/config.exs
config :ex_money, api_module: PTAX.ExchangeRates
```

## Usage

### Convert using the latest known rates

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL)
{:ok, %Money{}}
```

The lookup automatically walks back up to 7 days to find the most recent available data.

### Convert using rates for a specific date

```elixir
iex> PTAX.exchange(Money.new!(:GBP, "50"), :BRL, ~D[2026-05-15])
{:ok, Money.new!(:BRL, "337.63")}
```

Dates with no BCB data (weekends, holidays) return `{:error, {Money.ExchangeRateError, "404"}}`.

## See also

PTAX only provides the rate source. Once configured (see [Configuration](#configuration)), you can use `ex_money` directly for richer operations:

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
- [`Money.ExchangeRates`](https://hexdocs.pm/ex_money/Money.ExchangeRates.html) — access and configure the exchange rate backend
