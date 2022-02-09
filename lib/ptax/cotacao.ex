defmodule PTAX.Cotacao do
  @moduledoc "Define a estrutura de cotação de uma moeda"

  use TypedStruct
  use EnumType

  alias PTAX.{Error, Requests}

  defenum Boletim do
    value Abertura, "Abertura"
    value Intermediario, "Intermediário"
    value Fechamento, "Fechamento"
  end

  typedstruct enforce: true do
    field :compra, PTAX.valor()
    field :venda, PTAX.valor()
    field :cotado_em, DateTime.t()
    field :boletim, Boletim.t()
  end

  @doc "Retorna a cotação de compra e de venda de uma moeda para a data consultada"
  @spec get(
          moeda :: PTAX.moeda(),
          data :: Date.t(),
          boletim :: Boletim.t() | nil
        ) :: {:ok, t()} | {:error, Error.t()}
  def get(moeda, data, boletim \\ Boletim.Fechamento) do
    periodo = Date.range(data, data)

    case list(moeda, periodo, boletim) do
      {:ok, [cotacao]} ->
        {:ok, cotacao}

      {:ok, cotacoes} ->
        error =
          Error.new(
            code: :not_found,
            message: "Esperava no máximo um resultado, mas obteve #{length(cotacoes)}"
          )

        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc "Retorna lista de cotação de compra e de venda de uma moeda para um período consultado"
  @spec list(
          moeda :: PTAX.moeda(),
          periodo :: Date.Range.t(),
          boletim :: Boletim.t() | nil
        ) :: {:ok, list(t)} | {:error, Error.t()}
  def list(moeda, periodo, boletim \\ nil) do
    with {:ok, value} <- request(moeda, periodo) do
      result = value |> Enum.map(&parse/1) |> filter(boletim)

      {:ok, result}
    end
  end

  defp request(moeda, periodo) do
    params = [
      {"moeda", moeda},
      {"dataInicial", Timex.format!(periodo.first, "%m-%d-%Y", :strftime)},
      {"dataFinalCotacao", Timex.format!(periodo.last, "%m-%d-%Y", :strftime)}
    ]

    "/CotacaoMoedaPeriodo"
    |> Requests.get(opts: [odata_params: params])
    |> Requests.response()
  end

  defp parse(%{
         "cotacao_compra" => compra,
         "cotacao_venda" => venda,
         "data_hora_cotacao" => cotado_em,
         "tipo_boletim" => boletim
       }) do
    params = %{
      compra: Decimal.from_float(compra),
      venda: Decimal.from_float(venda),
      cotado_em:
        cotado_em
        |> Timex.parse!("{ISO:Extended}")
        |> Timex.Timezone.convert("America/Sao_Paulo"),
      boletim: Boletim.from(boletim)
    }

    struct!(__MODULE__, params)
  end

  defp filter(cotacoes, nil) do
    cotacoes
  end

  defp filter(cotacoes, boletim) when is_list(boletim) do
    Enum.filter(cotacoes, &(&1.boletim in boletim))
  end

  defp filter(cotacoes, boletim) do
    Enum.filter(cotacoes, &(&1.boletim == boletim))
  end
end
