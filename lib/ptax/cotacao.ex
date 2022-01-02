defmodule PTAX.Cotacao do
  @moduledoc "Define a estrutura de cotação de uma moeda"

  use TypedStruct
  use EnumType

  alias PTAX.Error

  defenum Boletim do
    value Abertura, "Abertura"
    value Intermediario, "Intermediário"
    value Fechamento, "Fechamento"
  end

  typedstruct enforce: true do
    field :compra, Decimal.t()
    field :venda, Decimal.t()
    field :cotado_em, DateTime.t()
    field :tipo_boletim, Boletim.t()
  end

  @doc "Retorna a cotação de compra e de venda de uma moeda para a data consultada"
  @spec get(
          moeda :: atom,
          data :: Date.t(),
          tipo_boletim :: Boletim.t() | nil
        ) :: {:ok, t()} | {:error, Error.t()}
  def get(moeda, data, tipo_boletim \\ Boletim.Fechamento) do
    periodo = Date.range(data, data)

    case list(moeda, periodo, tipo_boletim) do
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
          moeda :: atom,
          periodo :: Date.Range.t(),
          tipo_boletim :: Boletim.t() | nil
        ) :: {:ok, list(t)} | {:error, Error.t()}
  def list(moeda, periodo, tipo_boletim \\ nil) do
    with {:ok, value} <- PTAX.Requests.cotacao(moeda, periodo) do
      result = value |> Enum.map(&parse/1) |> filter(tipo_boletim)

      {:ok, result}
    end
  end

  defp parse(%{
         "cotacao_compra" => compra,
         "cotacao_venda" => venda,
         "data_hora_cotacao" => cotado_em,
         "tipo_boletim" => tipo_boletim
       }) do
    params = %{
      compra: Decimal.from_float(compra),
      venda: Decimal.from_float(venda),
      cotado_em:
        cotado_em
        |> Timex.parse!("{ISO:Extended}")
        |> Timex.Timezone.convert("America/Sao_Paulo"),
      tipo_boletim: Boletim.from(tipo_boletim)
    }

    struct!(__MODULE__, params)
  end

  defp filter(cotacoes, nil) do
    cotacoes
  end

  defp filter(cotacoes, tipo_boletim) when is_list(tipo_boletim) do
    Enum.filter(cotacoes, &(&1.tipo_boletim in tipo_boletim))
  end

  defp filter(cotacoes, tipo_boletim) do
    Enum.filter(cotacoes, &(&1.tipo_boletim == tipo_boletim))
  end
end
