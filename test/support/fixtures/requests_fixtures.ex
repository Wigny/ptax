defmodule PTAX.RequestsFixtures do
  @moduledoc false

  import Tesla.Mock

  def fixture() do
    mock(&env/1)
  end

  defp env(%{
         method: :get,
         url: "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/Moedas"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "nome_formatado" => "Libra Esterlina",
          "simbolo" => "GBP",
          "tipo_moeda" => "B"
        },
        %{
          "nome_formatado" => "Dólar dos Estados Unidos",
          "simbolo" => "USD",
          "tipo_moeda" => "A"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         method: :get,
         url:
           "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoMoedaPeriodoFechamento(codigoMoeda='GBP',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "cotacao_compra" => 7.5776,
          "cotacao_venda" => 7.5866,
          "data_hora_cotacao" => "2021-12-24 11:04:02.178",
          "tipo_boletim" => "Fechamento"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         method: :get,
         url:
           "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoMoedaPeriodoFechamento(codigoMoeda='USD',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "cotacao_compra" => 5.6541,
          "cotacao_venda" => 5.6591,
          "data_hora_cotacao" => "2021-12-24 11:04:02.178",
          "tipo_boletim" => "Fechamento"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         method: :get,
         url:
           "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoMoedaPeriodoFechamento(codigoMoeda='GBPS',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = ~s(/*{
      "codigo" : 500,
      "mensagem" : "Erro desconhecido"
    }*/)

    text(body)
  end
end
