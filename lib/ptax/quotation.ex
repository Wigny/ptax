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
    field :pair, Money.Pair.t()
    field :quoted_in, DateTime.t()
    field :bulletin, bulletin
  end

  @doc """
  Returns the quotation of a currency for the date


      iex> PTAX.Quotation.get(:USD, ~D[2021-12-24])
      {
        :ok,
        %PTAX.Quotation{
          pair: PTAX.Money.Pair.new("1.0", "1.0", :USD, :USD),
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
            pair: PTAX.Money.Pair.new("1.3417", "1.3421", :GBP, :USD),
            quoted_in: DateTime.from_naive!(~N[2021-12-24 10:08:31.922], "America/Sao_Paulo"),
            bulletin: PTAX.Quotation.Bulletin.Opening
          },
          %PTAX.Quotation{
            pair: PTAX.Money.Pair.new("1.3402", "1.3406", :GBP, :USD),
            quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.173], "America/Sao_Paulo"),
            bulletin: PTAX.Quotation.Bulletin.Intermediary
          },
          %PTAX.Quotation{
            pair: PTAX.Money.Pair.new("1.3402", "1.3406", :GBP, :USD),
            quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
            bulletin: PTAX.Quotation.Bulletin.Closing
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
      {"moeda", if(currency == :BRL, do: :USD, else: currency)},
      {"dataInicial", Timex.format!(period.first, "%m-%d-%Y", :strftime)},
      {"dataFinalCotacao", Timex.format!(period.last, "%m-%d-%Y", :strftime)}
    ]

    quotation_request = Requests.get("/CotacaoMoedaPeriodo", opts: [odata_params: params])

    with {:ok, quotation} <- Requests.response(quotation_request) do
      result =
        quotation
        |> Enum.map(&(&1 |> prepare(currency) |> parse()))
        |> filter(bulletin)

      {:ok, result}
    end
  end

  defp prepare(quotation, :BRL) do
    Map.merge(quotation, %{
      "simbolo" => "BRL",
      "tipo_moeda" => "A",
      "paridade_compra" => quotation["cotacao_compra"],
      "paridade_venda" => quotation["cotacao_venda"]
    })
  end

  defp prepare(quotation, currency_symbol) do
    "/Moedas?$filter=simbolo%20eq%20':currency'"
    |> Requests.get(opts: [path_params: [currency: currency_symbol]])
    |> Requests.response()
    |> elem(1)
    |> hd()
    |> Map.merge(quotation)
  end

  defp parse(value) do
    currency_symbol = String.to_existing_atom(value["simbolo"])

    {base_currency, quoted_currency} =
      case value["tipo_moeda"] do
        "A" -> {:USD, currency_symbol}
        "B" -> {currency_symbol, :USD}
      end

    params = %{
      pair:
        Money.Pair.new(
          value["paridade_compra"],
          value["paridade_venda"],
          base_currency,
          quoted_currency
        ),
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
