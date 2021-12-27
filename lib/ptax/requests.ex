defmodule PTAX.Requests do
  use Tesla

  @query ["$format": "json"]

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.PathParams
  plug Tesla.Middleware.JSON

  def moedas() do
    get("/Moedas", query: @query)
  end

  def cotacao(moeda \\ "USD", data \\ DateTime.now!("America/Sao_Paulo")) do
    params = [moeda: moeda, data: Calendar.strftime(data, "%m-%d-%Y")]

    get("/CotacaoMoedaDia(moeda=':moeda',dataCotacao=':data')",
      opts: [path_params: params],
      query: @query
    )
  end

  def cotacaoFechamento(
        moeda \\ "USD",
        dataInicial \\ DateTime.now!("America/Sao_Paulo"),
        dataFinal \\ DateTime.now!("America/Sao_Paulo")
      ) do
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
