defmodule PTAX.Cotacao do
  @moduledoc "Define a estrutura de cotação de uma moeda"

  use TypedStruct

  typedstruct enforce: true do
    field :compra, Decimal.t()
    field :venda, Decimal.t()
    field :cotado_em, DateTime.t()
  end

  @doc "Retorna a cotação de compra e de venda de uma moeda no fechamento para a data consultada"
  @spec get(atom, Date.t()) :: {:ok, t} | {:error, term}
  def get(moeda, data) do
    with {:ok, [fechamento | _value]} <- PTAX.Requests.cotacao_fechamento(moeda, data, data) do
      result = parse(fechamento)

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
