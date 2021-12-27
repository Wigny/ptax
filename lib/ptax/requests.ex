defmodule PTAX.Requests do
  use Tesla

  @query ["$format": "json"]

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.PathParams
  plug Tesla.Middleware.JSON

  @spec moedas :: Tesla.Env.result()
  def moedas() do
    get("/Moedas", query: @query)
  end

  @spec cotacaoFechamento(binary, Date.t(), Date.t()) :: Tesla.Env.result()
  def cotacaoFechamento(moeda, dataInicial, dataFinal) do
    params = [
      moeda: moeda,
      dataInicial: Calendar.strftime(dataInicial, "%m-%d-%Y"),
      dataFinal: Calendar.strftime(dataFinal, "%m-%d-%Y")
    ]

    get(
      "/CotacaoMoedaPeriodoFechamento(codigoMoeda=':moeda',dataInicialCotacao=':dataInicial',dataFinalCotacao=':dataFinal')",
      opts: [path_params: params],
      query: @query
    )
  end
end
