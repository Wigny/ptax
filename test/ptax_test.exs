defmodule PTAXTest do
  use ExUnit.Case

  doctest PTAX

  test "exchange/2 uses yesterday's rates when today's rates are not available" do
    yesterday = Date.add(Date.utc_today(), -1)
    money = Money.new!(:USD, "100")

    assert PTAX.exchange(money, :BRL) == PTAX.exchange(money, :BRL, yesterday)
  end

  test "exchange/3 propagates network errors" do
    assert {:error, {Money.ExchangeRateError, ":timeout"}} =
             PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-01-01])
  end
end
