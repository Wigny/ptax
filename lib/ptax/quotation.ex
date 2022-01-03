defmodule PTAX.Quotation do
  @moduledoc "Define a quotation structure for a currency"

  use TypedStruct
  use EnumType

  alias PTAX
  alias PTAX.Error

  defenum Bulletin do
    value Opening, "Abertura"
    value Intermediary, "Intermediário"
    value Closing, "Fechamento"
  end

  typedstruct enforce: true do
    field :buy, Decimal.t()
    field :sell, Decimal.t()
    field :quoted_in, DateTime.t()
    field :bulletin, Bulletin.t()
  end

  @doc "Returns the quotation of a currency for a date"
  @spec get(
          currency :: PTAX.currency(),
          date :: Date.t(),
          bulletin :: Bulletin.t() | nil
        ) :: {:ok, t()} | {:error, Error.t()}
  def get(currency, date, bulletin \\ Bulletin.Closing) do
    period = Date.range(date, date)

    case list(currency, period, bulletin) do
      {:ok, [quotation]} ->
        {:ok, quotation}

      {:ok, quotations} ->
        error =
          Error.new(
            code: :not_found,
            message: "Expected at most one result but got #{length(quotations)}"
          )

        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc "Returns a quotation list of a currency for a period"
  @spec list(
          currency :: PTAX.currency(),
          period :: Date.Range.t(),
          bulletin :: Bulletin.t() | nil
        ) :: {:ok, list(t)} | {:error, Error.t()}
  def list(currency, period, bulletin \\ nil) do
    with {:ok, value} <- PTAX.Requests.cotacao(currency, period) do
      result = value |> Enum.map(&parse/1) |> filter(bulletin)

      {:ok, result}
    end
  end

  defp parse(%{
         "cotacao_compra" => buy,
         "cotacao_venda" => sell,
         "data_hora_cotacao" => quoted_in,
         "tipo_boletim" => bulletin
       }) do
    params = %{
      buy: Decimal.from_float(buy),
      sell: Decimal.from_float(sell),
      quoted_in:
        quoted_in
        |> Timex.parse!("{ISO:Extended}")
        |> Timex.Timezone.convert("America/Sao_Paulo"),
      bulletin: Bulletin.from(bulletin)
    }

    struct!(__MODULE__, params)
  end

  defp filter(quotations, nil) do
    quotations
  end

  defp filter(quotations, bulletin) when is_list(bulletin) do
    Enum.filter(quotations, &(&1.bulletin in bulletin))
  end

  defp filter(quotations, bulletin) do
    Enum.filter(quotations, &(&1.bulletin == bulletin))
  end
end
