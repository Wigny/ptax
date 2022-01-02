defmodule PTAX.Conversor do
  @moduledoc "Agrega funções de conversão de moeda"

  alias PTAX.{Cotacao, Error}

  @type valor :: Decimal.decimal()
  @type moeda :: atom
  @type operacao :: :compra | :venda

  @type opts :: %{
          de: moeda,
          para: moeda,
          data: Date.t(),
          operacao: operacao,
          tipo_boletim: Cotacao.Boletim.t()
        }

  defguardp valid_operation?(operacao) when operacao in ~w[compra venda]a
  defguardp valid_currency?(moeda) when is_atom(moeda)
  defguardp is_base?(moeda) when moeda == :BRL

  defguardp valid_params?(opts)
            when valid_operation?(opts.operacao) and
                   valid_currency?(opts.de) and
                   valid_currency?(opts.para)

  defguardp has_base?(opts) when is_base?(opts.de) or is_base?(opts.para)

  @doc """
  Executa a conversão de um valor de uma moeda para outra

  ## Exemplo

      iex> PTAX.Conversor.run(15, %{de: :BRL, para: :GBP, data: ~D[2021-12-24], operacao: :venda, tipo_boletim: PTAX.Cotacao.Boletim.Fechamento})
      {:ok, #Decimal<1.9772>}
      iex> PTAX.Conversor.run(5, %{de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :compra, tipo_boletim: PTAX.Cotacao.Boletim.Fechamento})
      {:ok, #Decimal<28.2705>}
  """
  @spec run(valor, opts) :: {:ok, Decimal.t()} | {:error, Error.t()}

  def run(valor, opts) when valid_params?(opts) and has_base?(opts) do
    %{de: de, para: para, data: data, operacao: operacao, tipo_boletim: tipo_boletim} = opts
    {moeda_cotada, base_conversor} = cotar([de, para])

    with {:ok, %{^operacao => taxa}} <- Cotacao.get(moeda_cotada, data, tipo_boletim) do
      moeda_base = apply(Decimal, base_conversor, [valor, taxa])

      result = moeda_base |> Decimal.round(4) |> Decimal.normalize()
      {:ok, result}
    end
  end

  def run(valor, opts) when valid_params?(opts) do
    with {:ok, valor_brl} <- run(valor, %{opts | para: :BRL}) do
      run(valor_brl, %{opts | de: :BRL})
    end
  end

  defp cotar(moedas)
  defp cotar([:BRL, moeda]), do: {moeda, :div}
  defp cotar([moeda, :BRL]), do: {moeda, :mult}
end
