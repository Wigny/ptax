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

  @spec get(binary, Date.t()) :: {:ok, __MODULE__.t()} | {:error, term}
  def get(moeda, data) do
    with {:ok, %{body: body}} <- PTAX.Requests.cotacao_fechamento(moeda, data, data),
         [fechamento | _value] <- body["value"] do
      result = parse(fechamento)

      {:ok, result}
    else
      {:ok, _env} -> {:error, :unknown}
      {:error, error} -> {:error, error}
      [] -> {:error, :not_found}
    end
  end

  defp parse(%{
         "cotacao_compra" => compra,
         "cotacao_venda" => venda,
         "data_hora_cotacao" => data_hora,
         "tipo_boletim" => tipo_boletim
       }) do
    params = %{
      compra: Decimal.from_float(compra),
      venda: Decimal.from_float(venda),
      data_hora:
        data_hora
        |> NaiveDateTime.from_iso8601!()
        |> DateTime.from_naive!("America/Sao_Paulo"),
      tipo_boletim: Boletim.from(tipo_boletim)
    }

    struct!(__MODULE__, params)
  end
end
