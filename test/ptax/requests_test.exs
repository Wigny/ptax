defmodule PTAX.RequestsTest do
  use ExUnit.Case

  alias PTAX.Requests

  setup context do
    PTAX.RequestsFixtures.fixture(context)

    :ok
  end

  describe "requests" do
    test "currencies/0 returns data for supported currencies" do
      assert {:ok, [currency | _moedas]} = Requests.currencies()

      assert %{
               "nome_formatado" => "Libra Esterlina",
               "simbolo" => "GBP",
               "tipo_moeda" => "B"
             } = currency
    end

    @tag error: :network_error
    test "currencies/0 throws `network_error` error if there is an error making request" do
      assert {:error, error} = Requests.currencies()

      assert %PTAX.Error{code: :network_error} = error
    end

    test "quotation/2 returns the currency quote by period" do
      period = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:ok, quotations} = Requests.quotation(:GBP, period)

      assert %{
               "cotacao_compra" => 7.5776,
               "cotacao_venda" => 7.5866,
               "data_hora_cotacao" => "2021-12-24 11:04:02.178",
               "tipo_boletim" => "Fechamento"
             } = List.last(quotations)
    end

    @tag error: :not_found
    test "quotation/2 throws `:not_found` error if no data is returned" do
      period = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:error, error} = Requests.quotation(:USD, period)

      assert %PTAX.Error{code: :not_found} = error
    end

    test "quotation/2 throws `:server_error` error if there is server error" do
      period = Date.range(~D[2021-12-24], ~D[2021-12-24])
      assert {:error, error} = Requests.quotation(:GBPS, period)

      assert %PTAX.Error{code: :server_error} = error
    end
  end
end
