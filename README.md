# PTAX

PTAX is the official exchange rate published daily by the Brazilian Central Bank (Banco Central do Brasil, BCB). It is the reference rate used in financial contracts, tax reporting, and regulatory filings in Brazil.

Quotes are fetched from the BCB's [exchange rates page](https://www.bcb.gov.br/estabilidadefinanceira/cotacoestodas) and represent the closing bid and ask rates for each currency pair against the Brazilian Real (BRL). Each conversion uses the quote that matches its direction: the bid rate for the currency being sold into BRL and the ask rate for the currency being bought with BRL. A conversion between two non-BRL currencies goes through BRL, selling the source at its bid and buying the target at its ask.

## Installation

Add PTAX to your project's dependencies in `mix.exs`:

```elixir
# mix.exs
def deps do
  [
    {:ptax, "~> 3.0"}
  ]
end
```

PTAX starts its own isolated retriever, so `ex_money`'s default auto-started retriever isn't needed. Turn it off:

```elixir
# config/config.exs
config :ex_money, auto_start_exchange_rate_service: false
```

See [`ex_money`'s exchange rates service docs](https://ex-money.hexdocs.pm/readme.html#the-exchange-rates-service-process-supervision-and-startup) for details.

In scripts and Livebook notebooks, pass the same config to `Mix.install/2`:

```elixir
Mix.install(
  [{:ptax, "~> 3.0"}],
  config: [ex_money: [auto_start_exchange_rate_service: false]]
)
```

## Usage

### Convert using the latest known rates

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL)
{:ok, %Money{}}

iex> PTAX.exchange!(Money.new!(:USD, "100"), :BRL)
%Money{}
```

The lookup automatically walks back up to 7 days to find the most recent available data.

### Convert using rates for a specific date

```elixir
iex> PTAX.exchange(Money.new!(:GBP, "50"), :BRL, ~D[2026-05-15])
{:ok, Money.new!(:BRL, "337.60")}

iex> PTAX.exchange!(Money.new!(:GBP, "50"), :BRL, ~D[2026-05-15])
Money.new!(:BRL, "337.60")
```

Dates with no BCB data (weekends, holidays) return `{:error, reason}` or raise with the bang variants:

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
{:error, {Money.ExchangeRateError, "no exchange rates available for 2025-12-25"}}

iex> PTAX.exchange!(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
** (Money.ExchangeRateError) no exchange rates available for 2025-12-25
```

### Cross conversions

A conversion between two non-BRL currencies goes through BRL, selling the source at its bid and buying the target at its ask:

```elixir
iex> PTAX.exchange(Money.new!(:GBP, "100"), :EUR, ~D[2026-05-15])
{:ok, Money.new!(:EUR, "114.63")}
```

> #### Comparing against BCB's online converter {: .info}
>
> BCB's [converter](https://www.bcb.gov.br/conversao) routes non-BRL pairs through USD rather than BRL, and returns `114.65` for the conversion above. Expect a difference of around 0.01% on cross conversions when reconciling against it. Conversions involving BRL match it exactly.

## Testing

`PTAX` reads rates through the `PTAX.Rates` behaviour. Point `:ptax, :rates` at a stub implementing it and a test suite serves known rates instead of reaching BCB.

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

Each conversion asks for both sides: the currency being sold is read from the `:bid` rates and the currency being bought from the `:ask` rates. A rates map is keyed by currency, with each value the number of units of that currency per BRL, so a USD quote of 4.00 BRL is `Decimal.new("0.25")`.

```elixir
defmodule MyApp.ConversionTest do
  use ExUnit.Case, async: true

  test "converts at the published bid and ask" do
    Mox.stub(MyApp.RatesMock, :historic_rates, fn
      # USD bid 4.00, ask 5.00
      :bid, ~D[2026-05-15] -> {:ok, %{BRL: Decimal.new(1), USD: Decimal.new("0.25")}}
      :ask, ~D[2026-05-15] -> {:ok, %{BRL: Decimal.new(1), USD: Decimal.new("0.2")}}
    end)

    assert PTAX.exchange!(Money.new!(:USD, "100"), :BRL, ~D[2026-05-15]) == Money.new!(:BRL, "400.00")
    assert PTAX.exchange!(Money.new!(:BRL, "400"), :USD, ~D[2026-05-15]) == Money.new!(:USD, "80.00")
  end
end
```

## See also

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
