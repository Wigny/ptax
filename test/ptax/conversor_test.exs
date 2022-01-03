defmodule PTAX.ConversorTest do
  use ExUnit.Case
  alias PTAX.Conversor

  @valid_opts %{
    de: :USD,
    para: :GBP,
    data: ~D[2021-12-24],
    operacao: :sell,
    tipo_boletim: PTAX.Quotation.Bulletin.Closing
  }

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "conversor" do
    test "run/2 converte de uma moeda para outra" do
      assert {:ok, Decimal.from_float(11.5247)} == Conversor.run("15.45", @valid_opts)
    end

    test "run/2 lança erro se passado opções não suportadas" do
      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{@valid_opts | operacao: :vender})
      end

      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{@valid_opts | de: "USD"})
      end

      assert_raise FunctionClauseError, fn ->
        Conversor.run("15.45", %{@valid_opts | para: 5})
      end
    end
  end
end
