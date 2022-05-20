defmodule PTAX.Quotation do
  @moduledoc "Define a quotation structure for a currency"

  use TypedStruct

  alias PTAX.{Error, Money, Requests}

  @typep currency :: Money.currency()
  @typep date :: Date.t()
  @typep period :: Date.Range.t()
  @typep bulletin :: :opening | :intermediary | :closing

  @bulletin [
    opening: "Abertura",
    intermediary: "Intermediário",
    closing: "Fechamento"
  ]

  typedstruct enforce: true do
    field :pair, Money.Pair.t()
    field :quoted_in, DateTime.t()
    field :bulletin, bulletin
  end

  @doc """
  Returns the quotation of a currency for the date

  ## Examples

      iex> PTAX.Quotation.get(:USD, ~D[2021-12-24])
      {
        :ok,
        %PTAX.Quotation{
          pair: PTAX.Money.Pair.new("1.0", "1.0", :USD, :USD),
          quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
          bulletin: :closing
        }
      }
  """
  @spec get(currency, date, bulletin | nil) :: {:ok, t()} | {:error, Error.t()}
  def get(currency, date, bulletin \\ :closing) do
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
            bulletin: :opening
          },
          %PTAX.Quotation{
            pair: PTAX.Money.Pair.new("1.3402", "1.3406", :GBP, :USD),
            quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.173], "America/Sao_Paulo"),
            bulletin: :intermediary
          },
          %PTAX.Quotation{
            pair: PTAX.Money.Pair.new("1.3402", "1.3406", :GBP, :USD),
            quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
            bulletin: :closing
          }
        ]
      }
  """
  @spec list(currency, period, bulletin | nil) ::
          {:ok, list(t)} | {:error, Error.t()}
  def list(currency, period, bulletin \\ nil)

  def list(:BRL, period, bulletin) do
    opts = [
      odata: [
        params: [
          {"moeda", :USD},
          {"dataInicial", Timex.format!(period.first, "%m-%d-%Y", :strftime)},
          {"dataFinalCotacao", Timex.format!(period.last, "%m-%d-%Y", :strftime)}
        ],
        query: [
          filter: [{"tipoBoletim", @bulletin[bulletin]}]
        ]
      ]
    ]

    with {:ok, %{body: quotations}} <- Requests.get("/CotacaoMoedaPeriodo", opts: opts) do
      currency = %{"simbolo" => "BRL", "tipo_moeda" => "A"}

      result =
        quotations
        |> Enum.map(fn quotation ->
          quotation
          |> Map.put("paridade_compra", quotation["cotacao_compra"])
          |> Map.put("paridade_venda", quotation["cotacao_venda"])
        end)
        |> Enum.map(&parse(&1, currency))

      {:ok, result}
    end
  end

  def list(currency_symbol, period, bulletin) do
    opts = [
      odata: [
        params: [
          {"moeda", currency_symbol},
          {"dataInicial", Timex.format!(period.first, "%m-%d-%Y", :strftime)},
          {"dataFinalCotacao", Timex.format!(period.last, "%m-%d-%Y", :strftime)}
        ],
        query: [
          filter: [{"tipoBoletim", @bulletin[bulletin]}]
        ]
      ]
    ]

    with {:ok, %{body: quotations}} <- Requests.get("/CotacaoMoedaPeriodo", opts: opts) do
      currency_opts = [odata: [query: [filter: [{"simbolo", currency_symbol}]]]]
      {:ok, %{body: [currency]}} = Requests.get("/Moedas", opts: currency_opts)

      result = Enum.map(quotations, &parse(&1, currency))

      {:ok, result}
    end
  end

  defp parse(quotation, currency) do
    {base_currency, quoted_currency} = pair_symbols(currency["tipo_moeda"], currency["simbolo"])

    pair =
      Money.Pair.new(
        quotation["paridade_compra"],
        quotation["paridade_venda"],
        base_currency,
        quoted_currency
      )

    quoted_in =
      quotation["data_hora_cotacao"]
      |> Timex.parse!("{ISO:Extended}")
      |> Timex.Timezone.convert("America/Sao_Paulo")

    bulletin =
      @bulletin
      |> Enum.find(fn {_key, value} -> value == quotation["tipo_boletim"] end)
      |> elem(0)

    struct!(__MODULE__, %{pair: pair, quoted_in: quoted_in, bulletin: bulletin})
  end

  defp pair_symbols("A", symbol), do: {:USD, String.to_existing_atom(symbol)}
  defp pair_symbols("B", symbol), do: {String.to_existing_atom(symbol), :USD}
end
