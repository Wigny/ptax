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

  test "exchange/3 crosses non-BRL pairs through the closing rates" do
    # GBP is sold at its bid (6.75190) and EUR bought at its ask (5.89000).
    # Crossing the published USD parities instead, as BCB's own converter does,
    # would yield 114.65.
    assert PTAX.exchange(Money.new!(:GBP, "100"), :EUR, ~D[2026-05-15]) ==
             {:ok, Money.new!(:EUR, "114.63")}
  end
end
