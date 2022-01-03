defmodule PTAX.Requests do
  @moduledoc "Make HTTP requests to the PTAX API"

  use Tesla, only: [:get], docs: false

  alias PTAX
  alias PTAX.Error

  @type result :: {:ok, list} | {:error, Error.t()}

  @query ["$format": "json"]

  defguardp is_empty?(value) when value == []
  defguardp is_success?(status) when status in 200..299
  defguardp is_error?(status) when status in 500..599

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.PathParams
  plug PTAX.Requests.Case
  plug Tesla.Middleware.JSON

  @spec currencies :: result
  def currencies() do
    "/Moedas" |> get(query: @query) |> response()
  end

  @spec quotation(currency :: PTAX.currency(), period :: Date.Range.t()) :: result
  def quotation(currency, period) do
    params = [
      currency: currency,
      date_start: Timex.format!(period.first, "%m-%d-%Y", :strftime),
      date_end: Timex.format!(period.last, "%m-%d-%Y", :strftime)
    ]

    "/CotacaoMoedaPeriodo(moeda=':currency',dataInicial=':date_start',dataFinalCotacao=':date_end')"
    |> get(opts: [path_params: params], query: @query)
    |> response()
  end

  defp response({:ok, %{body: %{"value" => value}, status: status}})
       when is_success?(status) and not is_empty?(value) do
    {:ok, value}
  end

  defp response({:ok, %{status: status}}) when is_success?(status) do
    error = Error.new(code: :not_found, message: "Data not found for request")
    {:error, error}
  end

  defp response({:ok, %{status: status}}) when is_error?(status) do
    error = Error.new(code: :server_error, message: "Unknown error")
    {:error, error}
  end

  defp response({:error, _error}) do
    error = Error.new(code: :network_error, message: "Error making request")
    {:error, error}
  end
end
