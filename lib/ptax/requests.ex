defmodule PTAX.Requests do
  @moduledoc "Realiza requests HTTP para a API PTAX"

  use Tesla, only: [:get], docs: false

  alias PTAX.Error

  defguardp is_empty(value) when value == []
  defguardp is_success(status) when status in 200..299
  defguardp is_error(status) when status in 500..599

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.Query, [{"$format", "json"}]
  plug PTAX.Requests.ODataParams
  plug TeslaKeys.Middleware.Case
  plug Tesla.Middleware.JSON

  @spec response(Tesla.Env.result()) :: {:ok, list} | {:error, Error.t()}
  def response({:ok, %{body: %{"value" => value}, status: status}})
      when is_success(status) and not is_empty(value) do
    {:ok, value}
  end

  def response({:ok, %{status: status}}) when is_success(status) do
    error =
      Error.new(
        code: :not_found,
        message: "Dados não encontrados para a requisição (verifique se a data é um dia útil)"
      )

    {:error, error}
  end

  def response({:ok, %{status: status}}) when is_error(status) do
    error = Error.new(code: :server_error, message: "Erro desconhecido")
    {:error, error}
  end

  def response({:error, _error}) do
    error = Error.new(code: :network_error, message: "Erro ao realizar request")
    {:error, error}
  end
end
