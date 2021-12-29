defmodule PTAX.Moeda do
  @moduledoc "Define a estrutura de uma moeda"

  use TypedStruct

  typedstruct enforce: true do
    field :nome, String.t()
    field :simbolo, atom()
  end

  @doc """
  Retorna uma lista de moedas suportadas

  ## Exemplo

      iex> PTAX.Moeda.list()
      {:ok, [%PTAX.Moeda{nome: "Euro", simbolo: :EUR}, %PTAX.Moeda{nome: "Libra Esterlina", simbolo: :GBP}]}
  """
  @spec list :: {:ok, list(t)} | {:error, term}
  def list do
    with {:ok, %{body: body}} <- PTAX.Requests.moedas(), %{"value" => value} <- body do
      result = Enum.map(value, &parse/1)

      {:ok, result}
    else
      {:error, error} -> {:error, error}
      _error -> {:error, :unknown}
    end
  end

  defp parse(%{"nome_formatado" => nome, "simbolo" => simbolo}) do
    params = %{nome: nome, simbolo: String.to_atom(simbolo)}

    struct!(__MODULE__, params)
  end
end
