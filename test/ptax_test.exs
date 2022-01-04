defmodule PTAXTest do
  use ExUnit.Case

  alias PTAX

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "ptax" do
    test "convert/2 perform the conversion" do
      opts = [from: :USD, to: :GBP, date: ~D[2021-12-24]]

      assert {:ok, Decimal.from_float(11.5247)} == PTAX.convert("15.45", opts)
    end

    test "convert!/2 throws error if past invalid options" do
      opts = [from: :USD, to: :GBPS, date: ~D[2021-12-24]]

      assert_raise PTAX.Error, fn -> PTAX.convert!("15.45", opts) end
    end
  end
end
