defmodule PTAX.CotacaoTest do
  use ExUnit.Case

  alias PTAX.Cotacao

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "cotacao" do
    test "get/2 retorna o struct com os dados da cotacao" do
      assert {:ok, cotacao} = Cotacao.get(:USD, ~D[2021-12-24])

      assert %Cotacao{
               compra: Decimal.from_float(5.6541),
               venda: Decimal.from_float(5.6591),
               cotado_em: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
               boletim: Cotacao.Boletim.Fechamento
             } == cotacao
    end
  end
end
