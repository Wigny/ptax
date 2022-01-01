defmodule PTAX.ConversorTest do
  use ExUnit.Case
  alias PTAX.Conversor

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "conversor" do
    test "run/2 converte de uma moeda para outra" do
      opts = %{de: :USD, para: :GBP, data: ~D[2021-12-24], operacao: :venda}

      assert {:ok, Decimal.from_float(11.5247)} == Conversor.run("15.45", opts)
    end

    test "run/2 lança erro se passado opções não suportadas" do
      opts = %{de: :USD, para: :GBP, data: ~D[2021-12-24], operacao: :venda}

      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{opts | operacao: :vender})
      end

      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{opts | de: "USD"})
      end

      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{opts | para: 5})
      end
    end
  end
end
