defmodule PTAX.Requests do
  @moduledoc "Make HTTP requests to the PTAX API"

  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
  plug PTAX.Requests.Response
  plug PTAX.Requests.ODataParams, query: [format: "json"]
  plug Tesla.Middleware.PathParams
  plug TeslaKeys.Middleware.Case
  plug Tesla.Middleware.JSON
  # plug Tesla.Middleware.Logger
end
