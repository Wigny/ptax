defmodule PTAX.Moeda do
  use TypedStruct
  use EnumType

  defenum Tipo do
    value A, "A"
    value B, "B"
  end

  typedstruct do
    field :nome, String.t()
    field :simbolo, String.t(), enforce: true
    field :tipo, Tipo.t()
  end

  def list do
    {:ok, %{body: body}} = PTAX.Requests.moedas()

    Enum.map(body["value"], fn value ->
      struct!(__MODULE__, %{
        nome: value["nomeFormatado"],
        simbolo: value["simbolo"],
        tipo: Tipo.from(value["tipoMoeda"])
      })
    end)
  end
end
