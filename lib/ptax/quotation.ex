defmodule PTAX.Quotation do
  @moduledoc "Define a quotation structure for a currency"

  use TypedStruct
  use EnumType

  alias PTAX.{Error, Money, Requests}

  @typep currency :: Money.currency()
  @typep date :: Date.t()
  @typep period :: Date.Range.t()
  @typep bulletin :: Bulletin.t()

  defenum Bulletin do
    value Opening, "Abertura"
    value Intermediary, "Intermediário"
    value Closing, "Fechamento"
  end

  typedstruct enforce: true do
    field :bid, Money.t()
    field :ask, Money.t()
    field :quoted_in, DateTime.t()
    field :bulletin, Bulletin.t()
  end

  @doc """
  Returns the quotation of a currency for the date

  ## Examples

      iex> PTAX.Quotation.get(:USD, ~D[2021-12-24])
      {
        :ok,
        %PTAX.Quotation{
          bid: PTAX.Money.new(5.6541, :BRL),
          ask: PTAX.Money.new(5.6591, :BRL),
          quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
          bulletin: PTAX.Quotation.Bulletin.Closing
        }
      }
  """
  @spec get(currency, date, bulletin | nil) :: {:ok, t()} | {:error, Error.t()}
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

  @doc """
  Returns a quotation list of a currency for a period

  ## Examples

      iex> PTAX.Quotation.list(:GBP, Date.range(~D[2021-12-24], ~D[2021-12-24]))
      {
        :ok,
        [
         %PTAX.Quotation{
           bid: PTAX.Money.new(7.5605, :BRL),
           ask: PTAX.Money.new(7.5669, :BRL),
           quoted_in: DateTime.from_naive!(~N[2021-12-24 10:08:31.922], "America/Sao_Paulo"),
           bulletin: PTAX.Quotation.Bulletin.Opening
         },
         %PTAX.Quotation{
           bid: PTAX.Money.new(7.6032, :BRL),
           ask: PTAX.Money.new(7.6147, :BRL),
           quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.173], "America/Sao_Paulo"),
           bulletin: PTAX.Quotation.Bulletin.Intermediary
         },
         %PTAX.Quotation{
           bid: PTAX.Money.new(7.5776, :BRL),
           ask: PTAX.Money.new(7.5866, :BRL),
           quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
           bulletin: PTAX.Quotation.Bulletin.Closing
         }
        ]
      }

      iex> PTAX.Quotation.list(:GBP, Date.range(~D[2021-12-24], ~D[2021-12-24]), PTAX.Quotation.Bulletin.Opening)
      {
        :ok,
        [
         %PTAX.Quotation{
           bid: PTAX.Money.new(7.5605, :BRL),
           ask: PTAX.Money.new(7.5669, :BRL),
           quoted_in: DateTime.from_naive!(~N[2021-12-24 10:08:31.922], "America/Sao_Paulo"),
           bulletin: PTAX.Quotation.Bulletin.Opening
         }
        ]
      }
  """
  @spec list(
          currency,
          period,
          bulletin | list(bulletin) | nil
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

  defp parse(value) do
    params = %{
      bid: Money.new(value["cotacao_compra"]),
      ask: Money.new(value["cotacao_venda"]),
      quoted_in:
        value
        |> Map.get("data_hora_cotacao")
        |> Timex.parse!("{ISO:Extended}")
        |> Timex.Timezone.convert("America/Sao_Paulo"),
      bulletin: Bulletin.from(value["tipo_boletim"])
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
