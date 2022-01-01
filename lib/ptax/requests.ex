defmodule PTAX.Requests do
  @moduledoc "Módulo para trabalhar com requests para a API PTAX"

  use Tesla, only: [:get], docs: false

  alias PTAX.Error

  @type result :: {:ok, list} | {:error, Error.t()}

  @query ["$format": "json"]

  defguardp is_empty?(value) when length(value) == 0
  defguardp is_success?(status) when status in 200..299
  defguardp is_error?(status) when status in 500..599

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.PathParams
  plug PTAX.Requests.Case
  plug Tesla.Middleware.JSON

  @spec moedas :: result
  def moedas() do
    "/Moedas" |> get(query: @query) |> response()
  end

  @spec cotacao_fechamento(atom, Date.t(), Date.t()) :: result
  def cotacao_fechamento(moeda, data_inicial, data_final) do
    params = [
      moeda: moeda,
      data_inicial: Calendar.strftime(data_inicial, "%m-%d-%Y"),
      data_final: Calendar.strftime(data_final, "%m-%d-%Y")
    ]

    "/CotacaoMoedaPeriodoFechamento(codigoMoeda=':moeda',dataInicialCotacao=':data_inicial',dataFinalCotacao=':data_final')"
    |> get(opts: [path_params: params], query: @query)
    |> response()
  end

  defp response({:ok, %{body: %{"value" => value}, status: status}})
       when is_success?(status) and not is_empty?(value) do
    {:ok, value}
  end

  defp response({:ok, %{status: status}}) when is_success?(status) do
    error = Error.new(code: :not_found, message: "Dados não encontrados para a requisição")

    {:error, error}
  end

  defp response({:ok, %{status: status}}) when is_error?(status) do
    error =
      Error.new(
        code: :server_error,
        message: "Erro desconhecido",
        extra: %{http_status: status}
      )

    {:error, error}
  end

  defp response({:error, error}) do
    error =
      Error.new(
        code: :network_error,
        message: "Erro ao realizar request",
        extra: %{reason: error}
      )

    {:error, error}
  end
end
