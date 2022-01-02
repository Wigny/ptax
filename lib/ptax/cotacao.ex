defmodule PTAX.Cotacao do
  @moduledoc "Define a estrutura de cotação de uma moeda"

  use TypedStruct

  typedstruct enforce: true do
    field :compra, Decimal.t()
    field :venda, Decimal.t()
    field :cotado_em, DateTime.t()
  end

  @doc "Retorna a cotação de compra e de venda de uma moeda no fechamento para a data consultada"
  @spec get(atom, Date.t()) :: {:ok, t()} | {:error, PTAX.Error.t()}
  def get(moeda, data) do
    range = Date.range(data, data)

    with {:ok, [fechamento]} <- list(moeda, range), do: {:ok, fechamento}
  end

  @doc "Retorna lista de cotação de compra e de venda de uma moeda no fechamento para um período consultado"
  @spec list(atom, Date.Range.t()) :: {:ok, list(t)} | {:error, PTAX.Error.t()}
  def list(moeda, periodo) do
    with {:ok, value} <- PTAX.Requests.cotacao_fechamento(moeda, periodo) do
      result = Enum.map(value, &parse/1)

      {:ok, result}
    end
  end

  defp parse(%{
         "cotacao_compra" => compra,
         "cotacao_venda" => venda,
         "data_hora_cotacao" => cotado_em
       }) do
    params = %{
      compra: Decimal.from_float(compra),
      venda: Decimal.from_float(venda),
      cotado_em:
        cotado_em
        |> Timex.parse!("{ISO:Extended}")
        |> Timex.Timezone.convert("America/Sao_Paulo")
    }

    struct!(__MODULE__, params)
  end
end
