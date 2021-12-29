defmodule PTAX.Cotacao do
  @moduledoc "Define a estrutura de uma cotação de uma moeda"

  use TypedStruct

  typedstruct enforce: true do
    field :compra, Decimal.t()
    field :venda, Decimal.t()
    field :cotado_em, DateTime.t()
  end

  @doc "Retorna a cotação no fechamento de compra e venda de uma moeda para a data consultada"
  @spec get(atom, Date.t()) :: {:ok, __MODULE__.t()} | {:error, term}
  def get(moeda, data) do
    with {:ok, %{body: body}} <- PTAX.Requests.cotacao_fechamento(moeda, data, data),
         %{"value" => [fechamento | _value]} <- body do
      result = parse(fechamento)

      {:ok, result}
    else
      {:error, error} -> {:error, error}
      _error -> {:error, :unknown}
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
        |> NaiveDateTime.from_iso8601!()
        |> DateTime.from_naive!("America/Sao_Paulo")
    }

    struct!(__MODULE__, params)
  end
end
