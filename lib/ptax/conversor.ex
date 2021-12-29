defmodule PTAX.Conversor do
  alias PTAX.Cotacao

  @type valor :: Decimal.decimal()
  @type moeda :: atom
  @type operacao :: :compra | :venda

  @type opts :: %{de: moeda, para: moeda, data: Date.t(), operacao: operacao}

  @spec run(valor, opts) :: {:ok, Decimal.t()} | {:error, any}

  def run(valor, %{de: de, para: :BRL, data: data, operacao: operacao})
      when operacao in ~w[compra venda]a do
    with {:ok, %{^operacao => taxa}} <- Cotacao.get(de, data) do
      result =
        valor
        |> Decimal.mult(taxa)
        |> Decimal.round(4)
        |> Decimal.normalize()

      {:ok, result}
    end
  end

  def run(valor, %{de: :BRL, para: para, data: data, operacao: operacao})
      when operacao in ~w[compra venda]a do
    with {:ok, %{^operacao => taxa}} <- Cotacao.get(para, data) do
      result =
        valor
        |> Decimal.div(taxa)
        |> Decimal.round(4)
        |> Decimal.normalize()

      {:ok, result}
    end
  end

  def run(valor, opts) when opts.operacao in ~w[compra venda]a do
    with {:ok, valor_brl} <- run(valor, %{opts | para: :BRL}) do
      run(valor_brl, %{opts | de: :BRL})
    end
  end
end
