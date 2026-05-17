defmodule PTAXTest do
  use ExUnit.Case

  doctest PTAX

  test "exchange/2 uses yesterday's rates" do
    yesterday = Date.add(Date.utc_today(), -1)
    money = Money.new!(:USD, "100")

    assert PTAX.exchange(money, :BRL) == PTAX.exchange(money, :BRL, yesterday)
  end
end
