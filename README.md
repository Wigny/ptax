# PTAX

PTAX is the official exchange rate published daily by the Brazilian Central Bank (Banco Central do Brasil, BCB). It is the reference rate used in financial contracts, tax reporting, and regulatory filings in Brazil.

Quotes are fetched from the BCB's [exchange rates page](https://www.bcb.gov.br/estabilidadefinanceira/cotacoestodas) and represent the closing bid and ask rates for each currency pair against the Brazilian Real (BRL). The rate exposed by this library is the mid-point between those two quotes.

## Installation

Add PTAX to your project's dependencies in `mix.exs`:

```elixir
# mix.exs
def deps do
  [
    {:ptax, "~> 2.1"}
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
  [{:ptax, "~> 2.1"}],
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

## Using PTAX rates with `ex_money`

PTAX runs as an isolated, named `ex_money` retriever (`PTAX.Retriever`), so it never interferes with any other `ex_money` retriever your application runs — you're free to use other providers for other currencies alongside it.

To reach `ex_money`'s richer operations (arbitrary conversions, cross rates) with PTAX data, fetch rates from `PTAX.Retriever` and pass them to any `ex_money` function that accepts a rates map:

```elixir
rates = Money.ExchangeRates.Retriever.latest_rates(PTAX.Retriever)
Money.to_currency(Money.new!(:USD, "100"), :BRL, rates)

historic = Money.ExchangeRates.Retriever.historic_rates(PTAX.Retriever, ~D[2026-05-15])
Money.to_currency(Money.new!(:GBP, "50"), :BRL, historic)
```

## See also

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
- [`Money.ExchangeRates.Retriever`](https://hexdocs.pm/ex_money/Money.ExchangeRates.Retriever.html) — the retriever process and its named-instance functions
