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
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL)
{:ok, %Money{}}

iex> PTAX.exchange!(Money.new!(:USD, "100"), :BRL)
%Money{}
```

BCB publishes a bulletin only on business days, so the lookup walks back up to 7 days to find the most recent one.

### Convert using the quotes for a specific date

```elixir
iex> PTAX.exchange(Money.new!(:GBP, "50"), :BRL, ~D[2026-07-31])
{:ok, Money.new(:BRL, "341.8150000")}

iex> PTAX.exchange!(Money.new!(:GBP, "50"), :BRL, ~D[2026-07-31])
Money.new(:BRL, "341.8150000")
```

Dates with no bulletin (weekends, holidays) return an error, or raise with the bang variants:

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
{:error, %PTAX.QuotesNotFoundError{date: ~D[2025-12-25]}}

iex> PTAX.exchange!(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
** (PTAX.QuotesNotFoundError) no quotes published for 2025-12-25
```

Currencies BCB does not quote return a `PTAX.CurrencyNotQuotedError`:

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :ZWL, ~D[2026-07-31])
{:error, %PTAX.CurrencyNotQuotedError{currency: :ZWL}}
```

> #### Always convert in a single call {: .warning}
>
> BCB treats a conversion between two currencies other than BRL and USD as its own operation, not as a conversion into USD followed by one out of it. Routing an amount through an intermediate currency yourself does not reproduce the published result, and the difference reaches several percent on currencies with a wide spread.

## Caching

Bulletins are cached on disk, in the user cache directory by default. Set `:cache_dir` to store them elsewhere, or to `nil` to download the bulletin on every conversion:

```elixir
# config/config.exs
config :ptax, req_options: [cache_dir: "/var/cache/ptax"]
```

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

The callback receives the pair being converted and returns the rate from the first currency to the second, as a `Decimal`.

```elixir
defmodule MyApp.ConversionTest do
  use ExUnit.Case, async: true

  test "converts at the published rate" do
    Mox.stub(MyApp.RatesMock, :rate, fn
      :USD, :BRL, ~D[2026-07-31] -> {:ok, Decimal.new("5.4321")}
      :BRL, :USD, ~D[2026-07-31] -> {:ok, Decimal.new("0.1834")}
    end)

    assert PTAX.exchange!(Money.new!(:USD, "100"), :BRL, ~D[2026-07-31]) == Money.new(:BRL, "543.2100000")
    assert PTAX.exchange!(Money.new!(:BRL, "100"), :USD, ~D[2026-07-31]) == Money.new(:USD, "18.3400000")
  end
end
```

## See also

- [`ex_money`](https://hexdocs.pm/ex_money) — the `Money` type PTAX converts
