defmodule PTAX.RequestsTest do
  use ExUnit.Case

  alias PTAX.Requests

  setup context do
    PTAX.RequestsFixtures.fixture(context)

    :ok
  end

  describe "requests" do
    test "moedas/0 retorna os dados da moedas suportadas" do
      assert {:ok, [moeda | _moedas]} = Requests.moedas()

      assert %{
               "nome_formatado" => "Libra Esterlina",
               "simbolo" => "GBP",
               "tipo_moeda" => "B"
             } = moeda
    end

    @tag error: :network_error
    test "moedas/0 lança erro `network_error` se ocorrer erro ao realizar request" do
      assert {:error, error} = Requests.moedas()

      assert %PTAX.Error{code: :network_error, extra: %{reason: :nxdomain}} = error
    end

    test "cotacao_fechamento/3 retorna a cotação da moeda por período no fechamento" do
      assert {:ok, [fechamento | _value]} =
               Requests.cotacao_fechamento(:GBP, ~D[2021-12-24], ~D[2021-12-24])

      assert %{
               "cotacao_compra" => 7.5776,
               "cotacao_venda" => 7.5866,
               "data_hora_cotacao" => "2021-12-24 11:04:02.178",
               "tipo_boletim" => "Fechamento"
             } = fechamento
    end

    @tag error: :not_found
    test "cotacao_fechamento/3 lança erro `:not_found` se nenhum dado for retornado" do
      assert {:error, error} = Requests.cotacao_fechamento(:USD, ~D[2021-12-24], ~D[2021-12-24])

      assert %PTAX.Error{code: :not_found} = error
    end

    test "cotacao_fechamento/3 lança erro `:server_error` se houver erro de servidor" do
      assert {:error, error} = Requests.cotacao_fechamento(:GBPS, ~D[2021-12-24], ~D[2021-12-24])

      assert %PTAX.Error{code: :server_error, extra: %{http_status: 500}} = error
    end
  end
end
