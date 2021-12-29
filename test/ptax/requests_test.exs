defmodule PTAX.RequestsTest do
  use ExUnit.Case

  alias PTAX.Requests

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "requests" do
    test "moedas/0 retorna os dados da moedas suportadas" do
      assert {:ok, env} = Requests.moedas()

      assert env.status == 200
      assert %{"value" => value} = env.body

      assert %{
               "nome_formatado" => "Libra Esterlina",
               "simbolo" => "GBP",
               "tipo_moeda" => "B"
             } = hd(value)
    end

    test "cotacao_fechamento/3 retorna a cotação da moeda por período no fechamento" do
      assert {:ok, env} = Requests.cotacao_fechamento(:GBP, ~D[2021-12-24], ~D[2021-12-24])

      assert env.status == 200
      assert %{"value" => [fechamento | _value]} = env.body

      assert %{
               "cotacao_compra" => 7.5776,
               "cotacao_venda" => 7.5866,
               "data_hora_cotacao" => "2021-12-24 11:04:02.178",
               "tipo_boletim" => "Fechamento"
             } = fechamento
    end
  end
end
