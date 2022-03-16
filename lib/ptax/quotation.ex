defmodule PTAX.Quotation do
  @moduledoc "Define a quotation structure for a currency"

  use TypedStruct
  use EnumType

  alias PTAX.{Error, Requests}

  defenum Bulletin do
    value Opening, "Abertura"
    value Intermediary, "Intermediário"
    value Closing, "Fechamento"
  end

  typedstruct enforce: true do
    field :buy, PTAX.amount()
    field :sell, PTAX.amount()
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
    params = [
      {"moeda", currency},
      {"dataInicial", Timex.format!(period.first, "%m-%d-%Y", :strftime)},
      {"dataFinalCotacao", Timex.format!(period.last, "%m-%d-%Y", :strftime)}
    ]

    result = Requests.get("/CotacaoMoedaPeriodo", opts: [odata_params: params])

    with {:ok, value} <- Requests.response(result) do
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

  defp filter(quotations, bulletins) when is_list(bulletins) do
    Enum.filter(quotations, &(&1.bulletin in bulletins))
  end

  defp filter(quotations, bulletin) do
    Enum.filter(quotations, &(&1.bulletin == bulletin))
  end
end
