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

    test "cotacao/2 retorna a cotação da moeda por período" do
      periodo = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:ok, cotacoes} = Requests.cotacao(:GBP, periodo)

      assert %{
               "cotacao_compra" => 7.5776,
               "cotacao_venda" => 7.5866,
               "data_hora_cotacao" => "2021-12-24 11:04:02.178",
               "tipo_boletim" => "Fechamento"
             } = List.last(cotacoes)
    end

    @tag error: :not_found
    test "cotacao/2 lança erro `:not_found` se nenhum dado for retornado" do
      periodo = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:error, error} = Requests.cotacao(:USD, periodo)

      assert %PTAX.Error{code: :not_found} = error
    end

    test "cotacao/2 lança erro `:server_error` se houver erro de servidor" do
      periodo = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:error, error} = Requests.cotacao(:GBPS, periodo)

      assert %PTAX.Error{code: :server_error, extra: %{http_status: 500}} = error
    end
  end
end
