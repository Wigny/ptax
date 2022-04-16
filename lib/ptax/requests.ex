defmodule PTAX.Requests do
  @moduledoc "Make HTTP requests to the PTAX API"

  use Tesla, only: [:get], docs: false

  alias PTAX
  alias PTAX.Error

  defguardp is_empty(value) when value == []
  defguardp is_success(status) when status in 200..299
  defguardp is_error(status) when status in 500..599

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug Tesla.Middleware.Query, [{"$format", "json"}]
  plug PTAX.Requests.ODataParams
  plug Tesla.Middleware.PathParams
  plug TeslaKeys.Middleware.Case
  plug Tesla.Middleware.JSON

  @spec response(Tesla.Env.result()) :: {:ok, list} | {:error, Error.t()}
  def response({:ok, %{body: %{"value" => value}, status: status}})
      when is_success(status) and not is_empty(value) do
    {:ok, value}
  end

  def response({:ok, %{body: body, status: status}}) when is_success(status) do
    error =
      Error.new(
        code: :not_found,
        message: "Data not found",
        status: status,
        details: inspect(body)
      )

    {:error, error}
  end

  def response({:ok, %{body: body, status: status}}) when is_error(status) do
    error =
      Error.new(
        code: :server_error,
        message: "Unknown error",
        status: status,
        details: inspect(body)
      )

    {:error, error}
  end

  def response({:error, error}) do
    error = Error.new(code: :network_error, message: "Request error", details: inspect(error))
    {:error, error}
  end
end
