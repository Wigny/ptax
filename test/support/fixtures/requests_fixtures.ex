defmodule PTAX.RequestsFixtures do
  @moduledoc false

  import Tesla.Mock

  @base_url "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"

  def fixture(opts \\ %{}) do
    mock(&env(&1, opts))
  end

  defp env(%{url: "#{@base_url}/Moedas"}, %{error: :network_error}) do
    {:error, :nxdomain}
  end

  defp env(%{url: "#{@base_url}/Moedas"}, _opts) do
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

  defp env(
         %{
           url:
             "#{@base_url}/CotacaoMoedaPeriodoFechamento(codigoMoeda='GBP',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
         },
         _opts
       ) do
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

  defp env(
         %{
           url:
             "#{@base_url}/CotacaoMoedaPeriodoFechamento(codigoMoeda='USD',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
         },
         %{error: :not_found}
       ) do
    body = %{
      "@odata_context" => "",
      "value" => []
    }

    json(body)
  end

  defp env(
         %{
           url:
             "#{@base_url}/CotacaoMoedaPeriodoFechamento(codigoMoeda='USD',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
         },
         _opts
       ) do
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

  defp env(
         %{
           url:
             "#{@base_url}/CotacaoMoedaPeriodoFechamento(codigoMoeda='GBPS',dataInicialCotacao='12-24-2021',dataFinalCotacao='12-24-2021')"
         },
         _opts
       ) do
    body = ~s(/*{
      "codigo" : 500,
      "mensagem" : "Erro desconhecido"
    }*/)

    %Tesla.Env{status: 500, body: body}
  end
end
