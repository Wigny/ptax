# PTAX

PTAX is the official exchange rate published daily by the Brazilian Central Bank (Banco Central do Brasil, BCB). It is the reference rate used in financial contracts, tax reporting, and regulatory filings in Brazil. On every business day BCB publishes a bulletin on its [exchange rates page](https://www.bcb.gov.br/estabilidadefinanceira/cotacoestodas), listing, per currency, a bid and an ask against BRL and against USD.

`:ptax` is an Elixir library that converts `Money` amounts using those bulletins. Results match BCB's [online converter](https://www.bcb.gov.br/conversao).

## Installation

Add `:ptax` to your project's dependencies in `mix.exs`:

```elixir
# mix.exs
def deps do
  [
    {:ptax, "~> 3.0"}
  ]
end
```

## Usage

Converted amounts are rounded to 7 decimal places. The rate itself is never rounded, so scaling the amount scales the result exactly.

### Convert using the latest published quotes

```elixir
iex> PTAX.exchange(Money.new(:USD, "100"), :BRL)
{:ok, %Money{}}

iex> PTAX.exchange!(Money.new(:USD, "100"), :BRL)
%Money{}
```

BCB publishes a bulletin only on business days, so the lookup walks back up to 7 days to find the most recent one.

### Convert using the quotes for a specific date

```elixir
iex> PTAX.exchange(Money.new(:GBP, "50"), :BRL, ~D[2026-07-31])
{:ok, Money.new(:BRL, "341.8150000")}

iex> PTAX.exchange!(Money.new(:GBP, "50"), :BRL, ~D[2026-07-31])
Money.new(:BRL, "341.8150000")
```

Dates with no bulletin (weekends, holidays) return an error, or raise with the bang variants:

```elixir
iex> PTAX.exchange(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
{:error, %PTAX.QuotesNotFoundError{date: ~D[2025-12-25]}}

iex> PTAX.exchange!(Money.new(:USD, "100"), :BRL, ~D[2025-12-25])
** (PTAX.QuotesNotFoundError) no quotes published for 2025-12-25
```

Currencies BCB does not quote return a `Money.ExchangeRateError`:

```elixir
iex> PTAX.exchange(Money.new(:USD, "100"), :ZWL, ~D[2026-07-31])
{:error, %Money.ExchangeRateError{message: "No exchange rate is available for currency :ZWL"}}
```

> #### Always convert in a single call {: .warning}
>
> BCB treats a conversion between two currencies other than BRL and USD as its own operation, not as a conversion into USD followed by one out of it. Routing an amount through an intermediate currency yourself does not reproduce the published result, and the difference reaches several percent on currencies with a wide spread.

## Testing

`PTAX` reads quotes through the `PTAX.Rates` behaviour. Point `:ptax, :rates` at a stub implementing it and a test suite serves known rates instead of reaching BCB.

Any module implementing the behaviour works. With [Mox](https://hexdocs.pm/mox):

```elixir
# mix.exs
{:mox, "~> 1.2", only: :test}

# config/test.exs
config :ptax, rates: MyApp.RatesMock

# test/test_helper.exs
Mox.defmock(MyApp.RatesMock, for: PTAX.Rates)
ExUnit.start()
```

The callback receives the currency being converted from and returns rates relative to it: each value is how many units of that currency one unit of the base currency buys, and the base currency itself maps to `1`. A map built for one base currency cannot be reused for another, because the two directions of a pair read opposite sides of the spread and are not reciprocal.

```elixir
defmodule MyApp.ConversionTest do
  use ExUnit.Case, async: true

  test "converts at the published rate" do
    Mox.stub(MyApp.RatesMock, :rates, fn
      :USD, ~D[2026-07-31] -> {:ok, %{USD: Decimal.new(1), BRL: Decimal.new("5.4321")}}
      :BRL, ~D[2026-07-31] -> {:ok, %{BRL: Decimal.new(1), USD: Decimal.new("0.1834")}}
    end)

    assert PTAX.exchange!(Money.new(:USD, "100"), :BRL, ~D[2026-07-31]) == Money.new(:BRL, "543.2100000")
    assert PTAX.exchange!(Money.new(:BRL, "100"), :USD, ~D[2026-07-31]) == Money.new(:USD, "18.3400000")
  end
end
```

## See also

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
