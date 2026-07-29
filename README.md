# PTAX

PTAX is the official exchange rate published daily by the Brazilian Central Bank (Banco Central do Brasil, BCB). It is the reference rate used in financial contracts, tax reporting, and regulatory filings in Brazil.

Quotes are fetched from the BCB's [exchange rates page](https://www.bcb.gov.br/estabilidadefinanceira/cotacoestodas) and represent the closing bid and ask rates for each currency pair against the Brazilian Real (BRL). Each conversion uses the quote that matches its direction: the bid rate for the currency being sold into BRL and the ask rate for the currency being bought with BRL. A conversion between two non-BRL currencies goes through BRL, selling the source at its bid and buying the target at its ask.

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

## Using PTAX rates with `ex_money`

PTAX runs two isolated, named `ex_money` retrievers — one holding the bid rates and one the ask rates — so it never interferes with any other `ex_money` retriever your application runs.

To reach `ex_money`'s richer operations (arbitrary conversions, cross rates) with PTAX data, fetch a side's rates from `PTAX.Retriever` and pass them to any `ex_money` function that accepts a rates map:

```elixir
bid = PTAX.Retriever.latest_rates(:bid)
Money.to_currency(Money.new!(:USD, "100"), :BRL, bid)

ask = PTAX.Retriever.historic_rates(:ask, ~D[2026-05-15])
Money.to_currency(Money.new!(:BRL, "50"), :USD, ask)
```

## Testing

PTAX passes `:ptax, :req_options` straight to `Req`, so a test suite can serve canned rates instead of reaching BCB. Point it at [`Req.Test`](https://req.hexdocs.pm/Req.Test.html):

```elixir
# config/test.exs
config :ptax, req_options: [plug: {Req.Test, PTAX}]
```

`Req.Test` runs on `plug`, which `req` treats as an optional dependency, so declare it yourself:

```elixir
# mix.exs
{:plug, "~> 1.0", only: :test}
```

Stub bodies follow BCB's format, one currency per line: date, code, type, currency code, bid, ask, and the two USD parities, with `,` as the decimal separator and CRLF line endings.

```elixir
defmodule MyApp.ConversionTest do
  use ExUnit.Case, async: false

  setup {Req.Test, :set_req_test_to_shared}

  test "converts at the published bid and ask" do
    Req.Test.stub(PTAX, fn conn ->
      Req.Test.text(conn, "15/05/2026;220;A;USD;5,00000000;5,50000000;1,00000000;1,00000000\r\n")
    end)

    assert PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-05-15]) ==
             {:ok, Money.new!(:BRL, "500.00")}

    assert PTAX.exchange(Money.new!(:BRL, "550"), :USD, ~D[2026-05-15]) ==
             {:ok, Money.new!(:USD, "100.00")}
  end

  test "reports a date with no data" do
    Req.Test.stub(PTAX, fn conn -> Plug.Conn.send_resp(conn, 404, "") end)

    assert PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-05-19]) ==
             {:error, {Money.ExchangeRateError, "no exchange rates available for 2026-05-19"}}
  end

  test "surfaces a network failure" do
    Req.Test.stub(PTAX, fn conn -> Req.Test.transport_error(conn, :timeout) end)

    assert PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-05-18]) ==
             {:error, {Money.ExchangeRateError, "timeout"}}
  end
end
```

The shared `setup` and `async: false` are both required: PTAX's retrievers are long-lived processes of its own supervision tree, so a stub owned by the test process is invisible to them.

> #### Allowances are not a way around `async: false` {: .warning}
>
> `Req.Test.allow/3` grants one named process access to one test's stub, so it does not help here: every test shares the same two retriever processes, and concurrent tests displace each other's allowances. Some then fail with `cannot find mock/stub`, while others silently convert at another test's rates. Tests still pass whenever they happen not to overlap, which makes this easy to miss.

> #### Each date is fetched once {: .info}
>
> Rates are cached per date for the lifetime of the run, so changing what the stub serves for a date already converted has no effect. Give each test its own date instead.

To keep tests `async: true` and avoid the `plug` dependency, set `adapter:` instead of `plug:` to a module whose `run/1` returns `{request, %Req.Response{}}`. Fixtures then live in that one module rather than in each test.

## See also

- [`Money.to_currency/2,3`](https://hexdocs.pm/ex_money/Money.html#to_currency/3) — convert between any two currencies
- [`Money.cross_rate/2`](https://hexdocs.pm/ex_money/Money.html#cross_rate/2) — derive a cross rate between two currencies
- [`Money.ExchangeRates.Retriever`](https://hexdocs.pm/ex_money/Money.ExchangeRates.Retriever.html) — the retriever process and its named-instance functions
