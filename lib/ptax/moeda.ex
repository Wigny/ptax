defmodule PTAX.Moeda do
  @moduledoc "Define a estrutura de uma moeda"

  use TypedStruct

  typedstruct enforce: true do
    field :nome, binary
    field :simbolo, atom
  end

  @doc """
  Retorna uma lista de moedas suportadas

  ## Exemplo

      iex> PTAX.Moeda.list()
      {:ok, [%PTAX.Moeda{nome: "Euro", simbolo: :EUR}, %PTAX.Moeda{nome: "Libra Esterlina", simbolo: :GBP}]}
  """
  @spec list :: {:ok, list(t)} | {:error, PTAX.Error.t()}
  def list do
    with {:ok, value} <- PTAX.Requests.moedas() do
      result = Enum.map(value, &parse/1)

      {:ok, result}
    end
  end

  defp parse(%{"nome_formatado" => nome, "simbolo" => simbolo}) do
    params = %{nome: nome, simbolo: String.to_atom(simbolo)}

    struct!(__MODULE__, params)
  end
end
