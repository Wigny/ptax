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
