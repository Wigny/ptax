# PTAX

A currency converter that uses the API provided by the Brazilian Open Data Portal to perform quotes

## Installation

This package can be installed by adding `ptax` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ptax, "~> 0.1"}
  ]
end
```

## Configuration

Install and configure a Tesla adapter:

```elixir
# config/config.exs

config :tesla, adapter: Tesla.Adapter.Hackney
```

> See Tesla [installation](https://hexdocs.pm/tesla/readme.html#installation) and [adapters](https://hexdocs.pm/tesla/readme.html#adapters) docs.

## Usage

### Listing supported currencies

```elixir
iex> PTAX.currencies()
{:ok, [:EUR, :GBP, ...]}
```

### Listing a currency quotation for a date range

```elixir
iex> PTAX.Quotation.list(:GBP, Date.range(~D[2021-12-24], ~D[2021-12-26]))
{:ok, [%PTAX.Quotation{...}, ...]}
```

### Getting a currency quotation for a specific date and bulletin

```elixir
iex> PTAX.Quotation.get(:GBP, ~D[2021-12-24], PTAX.Quotation.Bulletin.Closing)
{:ok, %PTAX.Quotation{...}}
```

### Exchange a currency amount to another

```elixir
iex> PTAX.exchange(PTAX.Money.new(5, :GBP), to: :EUR, date: ~D[2021-12-24])
{:ok, #Money<5.918, EUR>}
```

### Combine two currency pairs, based on USD as the common currency

```elixir
iex> alias PTAX.Money.Pair
...> gbp_usd = Pair.new(1.3402, 1.3406, :GBP, :USD)
...> eur_usd = Pair.new(1.1319, 1.1323, :EUR, :USD)
...> Pair.combine(gbp_usd, eur_usd)
#Money.Pair<1.1836086/1.1843802, GBP/EUR>
```

## Exchange a currency amount given the currency pair

```elixir
iex> alias PTAX.Money
...> pair = Money.Pair.new(1.1836086, 1.1843802, :GBP, :EUR)
...> Money.exchange(Money.new(5, :GBP), pair)
#Money<5.918, EUR>
...> Money.exchange(Money.new(5, :EUR), pair)
#Money<4.2216, GBP>
```
