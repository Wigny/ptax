defmodule PTAX.Conversor do
  @moduledoc "Agrega funções de conversão de moeda"

  alias PTAX.Cotacao

  @type valor :: Decimal.decimal()
  @type moeda :: atom
  @type operacao :: :compra | :venda

  @type opts :: %{de: moeda, para: moeda, data: Date.t(), operacao: operacao}

  defguardp valid_operation?(operacao) when operacao in ~w[compra venda]a
  defguardp to_base?(de, para) when :BRL in [de, para]

  @doc """
  Executa a conversão de um valor de uma moeda para outra

  ## Exemplo

      iex> PTAX.Conversor.run(15, %{de: :BRL, para: :GBP, data: ~D[2021-12-24], operacao: :venda})
      {:ok, #Decimal<1.9772>}
      iex> PTAX.Conversor.run(5, %{de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :compra})
      {:ok, #Decimal<28.2705>}
  """
  @spec run(valor, opts) :: {:ok, Decimal.t()} | {:error, any}

  def run(valor, %{de: de, para: para, data: data, operacao: operacao})
      when valid_operation?(operacao) and to_base?(de, para) do
    {moeda_cotada, conversor} = cotar(de, para)

    with {:ok, %{^operacao => taxa}} <- Cotacao.get(moeda_cotada, data) do
      moeda_base = apply(Decimal, conversor, [valor, taxa])

      result = moeda_base |> Decimal.round(4) |> Decimal.normalize()
      {:ok, result}
    end
  end

  def run(valor, opts) do
    with {:ok, valor_brl} <- run(valor, %{opts | para: :BRL}) do
      run(valor_brl, %{opts | de: :BRL})
    end
  end

  defp cotar(de, para)
  defp cotar(:BRL, moeda), do: {moeda, :div}
  defp cotar(moeda, :BRL), do: {moeda, :mult}
end
