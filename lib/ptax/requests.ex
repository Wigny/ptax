defmodule PTAX.Requests do
  use Tesla, only: [:get], docs: false

  @query ["$format": "json"]

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.PathParams
  plug PTAX.Requests.Case
  plug Tesla.Middleware.JSON

  @spec moedas :: Tesla.Env.result()
  def moedas() do
    get("/Moedas", query: @query)
  end

  @spec cotacao_fechamento(binary, Date.t(), Date.t()) :: Tesla.Env.result()
  def cotacao_fechamento(moeda, data_inicial, data_final) do
    params = [
      moeda: moeda,
      data_inicial: Calendar.strftime(data_inicial, "%m-%d-%Y"),
      data_final: Calendar.strftime(data_final, "%m-%d-%Y")
    ]

    get(
      "/CotacaoMoedaPeriodoFechamento(codigoMoeda=':moeda',dataInicialCotacao=':data_inicial',dataFinalCotacao=':data_final')",
      opts: [path_params: params],
      query: @query
    )
  end
end
