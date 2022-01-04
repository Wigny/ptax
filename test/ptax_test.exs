defmodule PTAXTest do
  use ExUnit.Case

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "ptax" do
    test "converter/2 executa a conversão" do
      opts = [de: :USD, para: :GBP, data: ~D[2021-12-24]]

      assert {:ok, Decimal.from_float(11.5247)} == PTAX.converter("15.45", opts)
    end

    test "converter!/2 lança erro se passado opções inválidas" do
      opts = [de: :USD, para: :GBPS, data: ~D[2021-12-24]]

      assert_raise PTAX.Error, fn -> PTAX.converter!("15.45", opts) end
    end
  end
end
