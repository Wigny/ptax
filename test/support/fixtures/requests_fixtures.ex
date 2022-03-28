defmodule PTAX.RequestsFixtures do
  @moduledoc false

  import Tesla.Mock

  @base_url "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"

  def fixture() do
    mock(&env/1)
  end

  defp env(%{url: "#{@base_url}/Moedas?$filter=simbolo%20eq%20'GBP'"}) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "nome_formatado" => "Libra Esterlina",
          "simbolo" => "GBP",
          "tipo_moeda" => "B"
        }
      ]
    }

    json(body)
  end

  defp env(%{url: "#{@base_url}/Moedas?$filter=simbolo%20eq%20'USD'"}) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "nome_formatado" => "Dólar dos Estados Unidos",
          "simbolo" => "USD",
          "tipo_moeda" => "A"
        }
      ]
    }

    json(body)
  end

  defp env(%{url: "#{@base_url}/Moedas?$filter=simbolo%20eq%20'EUR'"}) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "nome_formatado" => "Euro",
          "simbolo" => "EUR",
          "tipo_moeda" => "B"
        }
      ]
    }

    json(body)
  end

  defp env(%{url: "#{@base_url}/Moedas"}) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "nome_formatado" => "Libra Esterlina",
          "simbolo" => "GBP",
          "tipo_moeda" => "B"
        },
        %{
          "nome_formatado" => "Euro",
          "simbolo" => "EUR",
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
         url:
           "#{@base_url}/CotacaoMoedaPeriodo(moeda='GBP',dataInicial='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "cotacao_compra" => 7.5605,
          "cotacao_venda" => 7.5669,
          "data_hora_cotacao" => "2021-12-24 10:08:31.922",
          "paridade_compra" => 1.3417,
          "paridade_venda" => 1.3421,
          "tipo_boletim" => "Abertura"
        },
        %{
          "cotacao_compra" => 7.6032,
          "cotacao_venda" => 7.6147,
          "data_hora_cotacao" => "2021-12-24 11:04:02.173",
          "paridade_compra" => 1.3402,
          "paridade_venda" => 1.3406,
          "tipo_boletim" => "Intermediário"
        },
        %{
          "cotacao_compra" => 7.5776,
          "cotacao_venda" => 7.5866,
          "data_hora_cotacao" => "2021-12-24 11:04:02.178",
          "paridade_compra" => 1.3402,
          "paridade_venda" => 1.3406,
          "tipo_boletim" => "Fechamento"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         url:
           "#{@base_url}/CotacaoMoedaPeriodo(moeda='USD',dataInicial='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "cotacao_compra" => 5.635,
          "cotacao_venda" => 5.6381,
          "data_hora_cotacao" => "2021-12-24 10:08:31.922",
          "paridade_compra" => 1.0,
          "paridade_venda" => 1.0,
          "tipo_boletim" => "Abertura"
        },
        %{
          "cotacao_compra" => 5.6732,
          "cotacao_venda" => 5.6801,
          "data_hora_cotacao" => "2021-12-24 11:04:02.173",
          "paridade_compra" => 1.0,
          "paridade_venda" => 1.0,
          "tipo_boletim" => "Intermediário"
        },
        %{
          "cotacao_compra" => 5.6541,
          "cotacao_venda" => 5.6591,
          "data_hora_cotacao" => "2021-12-24 11:04:02.178",
          "paridade_compra" => 1.0,
          "paridade_venda" => 1.0,
          "tipo_boletim" => "Fechamento"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         url:
           "#{@base_url}/CotacaoMoedaPeriodo(moeda='EUR',dataInicial='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = %{
      "@odata_context" => "",
      "value" => [
        %{
          "cotacao_compra" => 6.3794,
          "cotacao_venda" => 6.3835,
          "data_hora_cotacao" => "2021-12-24 10:08:31.922",
          "paridade_compra" => 1.1321,
          "paridade_venda" => 1.1322,
          "tipo_boletim" => "Abertura"
        },
        %{
          "cotacao_compra" => 6.4215,
          "cotacao_venda" => 6.4316,
          "data_hora_cotacao" => "2021-12-24 11:04:02.173",
          "paridade_compra" => 1.1319,
          "paridade_venda" => 1.1323,
          "tipo_boletim" => "Intermediário"
        },
        %{
          "cotacao_compra" => 6.3999,
          "cotacao_venda" => 6.4078,
          "data_hora_cotacao" => "2021-12-24 11:04:02.178",
          "paridade_compra" => 1.1319,
          "paridade_venda" => 1.1323,
          "tipo_boletim" => "Fechamento"
        }
      ]
    }

    json(body)
  end

  defp env(%{
         url:
           "#{@base_url}/CotacaoMoedaPeriodo(moeda='GBPS',dataInicial='12-24-2021',dataFinalCotacao='12-24-2021')"
       }) do
    body = ~s(/*{
      "codigo" : 500,
      "mensagem" : "Erro desconhecido"
    }*/)

    %Tesla.Env{status: 500, body: body}
  end
end
