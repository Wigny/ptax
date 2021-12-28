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

  @spec list :: {:ok, list(__MODULE__.t())} | {:error, term}
  def list do
    with {:ok, %{body: body}} <- PTAX.Requests.moedas() do
      result = Enum.map(body["value"], &parse/1)

      {:ok, result}
    else
      {:ok, _env} -> {:error, :unknown}
      {:error, error} -> {:error, error}
    end
  end

  defp parse(%{"nome_formatado" => nome, "simbolo" => simbolo, "tipo_moeda" => tipo}) do
    params = %{nome: nome, simbolo: simbolo, tipo: Tipo.from(tipo)}

    struct!(__MODULE__, params)
  end
end
