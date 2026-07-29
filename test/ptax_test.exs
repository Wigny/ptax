defmodule PTAXTest do
  use ExUnit.Case

  doctest PTAX

  test "exchange/2 uses yesterday's rates when today's rates are not available" do
    yesterday = Date.add(Date.utc_today(), -1)
    money = Money.new!(:USD, "100")

    assert PTAX.exchange(money, :BRL) == PTAX.exchange(money, :BRL, yesterday)
  end

  test "exchange/3 propagates network errors" do
    assert {:error, {Money.ExchangeRateError, "timeout"}} =
             PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-01-01])
  end

  test "exchange/2 returns an error for an unknown target currency" do
    assert {:error, {Money.UnknownCurrencyError, _message}} =
             PTAX.exchange(Money.new!(:USD, "100"), :XYZ)
  end

  test "exchange/3 reads both quote sides for the same day" do
    # The bid and ask retrievers read the same day, each caching its own side's
    # rates: USD is sold at the bid (5.10) and bought at the ask (5.20).
    assert PTAX.exchange(Money.new!(:USD, "100"), :BRL, ~D[2026-06-10]) ==
             {:ok, Money.new!(:BRL, "510.00")}

    assert PTAX.exchange(Money.new!(:BRL, "520"), :USD, ~D[2026-06-10]) ==
             {:ok, Money.new!(:USD, "100.00")}
  end
end
