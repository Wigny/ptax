defmodule PTAX do
  @moduledoc """
  Agrega funções de listagem e conversão de moedas suportadas
  """

  alias PTAX.{Conversor, Cotacao, Error, Moeda}

  @type valor :: Decimal.decimal()
  @type moeda :: atom()
  @type operacao :: :compra | :venda

  @type converter_opts ::
          Conversor.opts()
          | [
              de: moeda,
              para: moeda,
              data: Date.t() | nil,
              operacao: operacao | nil,
              boletim: Cotacao.Boletim.t() | nil
            ]

  @spec moedas :: {:ok, list(Moeda.t())} | {:error, Error.t()}
  defdelegate moedas, to: Moeda, as: :list

  @doc """
  Converte um valor de uma moeda para outra

  ## Exemplo

      iex> PTAX.converter(5, de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :compra, boletim: PTAX.Cotacao.Boletim.Fechamento)
      {:ok, #Decimal<28.2705>}
  """
  @spec converter(
          valor :: valor,
          opts :: converter_opts
        ) :: {:ok, Decimal.t()} | {:error, Error.t()}

  def converter(valor, opts) when is_list(opts) do
    default_opts = %{
      data: "America/Sao_Paulo" |> Timex.now() |> Timex.to_date(),
      operacao: :venda,
      boletim: Cotacao.Boletim.Fechamento
    }

    opts = Enum.into(opts, default_opts)
    converter(valor, opts)
  end

  def converter(valor, opts) when is_map(opts) do
    Conversor.run(valor, opts)
  end

  @doc """
  Semelhante a `converter/2`, mas gera um erro se o valor não puder ser convertido.

  ## Exemplo

      iex> PTAX.converter!(5, de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :compra, boletim: PTAX.Cotacao.Boletim.Fechamento)
      #Decimal<28.2705>
  """
  @spec converter!(valor :: valor, opts :: converter_opts) :: Decimal.t()
  def converter!(valor, opts) do
    case converter(valor, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
