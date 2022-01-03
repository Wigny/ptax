defmodule PTAX.CurrencyTest do
  use ExUnit.Case

  alias PTAX.Currency

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "currency" do
    test "get/2 returns the struct with the currency data" do
      assert {:ok, currencies} = Currency.list()

      assert [
               %Currency{name: "Pound Sterling", symbol: :GBP},
               %Currency{name: "US Dollar", symbol: :USD}
             ] == currencies
    end
  end
end
