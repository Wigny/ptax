defmodule PTAX.Cotacao do
  use TypedStruct
  use EnumType

  defenum Boletim do
    value Abertura, "Abertura"
    value Intermediario, "Intermediário"
    value Fechamento, "Fechamento"
  end

  typedstruct enforce: true do
    field :compra, Decimal.t()
    field :venda, Decimal.t()
    field :data_hora, DateTime.t()
    field :tipo_boletim, Boletim.t()
  end

  def get(moeda, data) do
    {:ok, %{body: body}} = PTAX.Requests.cotacaoFechamento(moeda, data, data)

    if cotacao = List.first(body["value"]) do
      struct!(__MODULE__, %{
        compra: Decimal.from_float(cotacao["cotacaoCompra"]),
        venda: Decimal.from_float(cotacao["cotacaoVenda"]),
        data_hora:
          cotacao["dataHoraCotacao"]
          |> NaiveDateTime.from_iso8601!()
          |> DateTime.from_naive!("America/Sao_Paulo"),
        tipo_boletim: Boletim.from(cotacao["tipoBoletim"])
      })
    end
  end
end
