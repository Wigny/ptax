# PTAX

PTAX is the official exchange rate published daily by the Brazilian Central Bank (Banco Central do Brasil, BCB). It is the reference rate used in financial contracts, tax reporting, and regulatory filings in Brazil.

Quotes are fetched from the BCB's [exchange rates page](https://www.bcb.gov.br/estabilidadefinanceira/cotacoestodas) and represent the closing bid and ask rates for each currency pair against the Brazilian Real (BRL). The rate exposed by this library is the mid-point between those two quotes.

## Installation

Add the dependency and configure `ex_money` to use PTAX as its rate source:

```elixir
# mix.exs
def deps do
  [
    {:ptax, "~> 2.0"}
  ]
end

# config/config.exs
config :ex_money, api_module: PTAX.ExchangeRates
```

In scripts and Livebook notebooks:

```elixir
Mix.install(
  [{:ptax, "~> 2.0"}],
  config: [ex_money: [api_module: PTAX.ExchangeRates]]
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
{:ok, Money.new!(:BRL, "337.63")}

iex> PTAX.exchange!(Money.new!(:GBP, "50"), :BRL, ~D[2026-05-15])
Money.new!(:BRL, "337.63")
```

Dates with no BCB data (weekends, holidays) return `{:error, reason}` or raise with the bang variants:

```elixir
iex> PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
{:error, {Money.ExchangeRateError, "no exchange rates available for 2025-12-25"}}

iex> PTAX.exchange!(Money.new!(:USD, "100"), :BRL, ~D[2025-12-25])
** (Money.ExchangeRateError) no exchange rates available for 2025-12-25
```

## See also

PTAX only provides the rate source. Once configured (see [Configuration](#configuration)), you can use `ex_money` directly for richer operations:

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
- [`Money.ExchangeRates`](https://hexdocs.pm/ex_money/Money.ExchangeRates.html) — access and configure the exchange rate backend
