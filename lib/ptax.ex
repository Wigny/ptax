defmodule PTAX do
  @moduledoc """
  Agrega funções de listagem e conversão de moedas suportadas
  """

  alias PTAX.{Conversor, Quotation, Error, Moeda}

  @type currency :: atom()

  @type converter_opts :: [
          de: Conversor.moeda(),
          para: Conversor.moeda(),
          data: Date.t() | nil,
          operacao: Conversor.operacao() | nil,
          tipo_boletim: Quotation.Boletim.t() | nil
        ]

  @spec moedas :: list(Moeda.t()) | {:error, Error.t()}
  defdelegate moedas, to: Moeda, as: :list

  @doc """
  Converte um valor de uma moeda para outra

  ## Exemplo

      iex> PTAX.converter(5, de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :buy, tipo_boletim: PTAX.Quotation.Bulletin.Closing)
      {:ok, #Decimal<28.2705>}
  """
  @spec converter(
          valor :: Conversor.valor(),
          opts :: converter_opts | Conversor.opts()
        ) :: {:ok, Decimal.t()} | {:error, Error.t()}

  def converter(valor, opts) when is_list(opts) do
    default_opts = %{
      data: "America/Sao_Paulo" |> Timex.now() |> Timex.to_date(),
      operacao: :sell,
      tipo_boletim: Quotation.Bulletin.Closing
    }

    opts = Enum.into(opts, default_opts)
    converter(valor, opts)
  end

  def converter(valor, opts) do
    Conversor.run(valor, opts)
  end

  @doc """
  Semelhante a `converter/2`, mas gera um erro se o valor não puder ser convertido.

  ## Exemplo

      iex> PTAX.converter!(5, de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :buy, tipo_boletim: PTAX.Quotation.Bulletin.Closing)
      #Decimal<28.2705>
  """
  @spec converter!(
          valor :: Conversor.valor(),
          opts :: converter_opts | Conversor.opts()
        ) :: Decimal.t()

  def converter!(valor, opts) do
    case converter(valor, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec base_currency :: currency
  def base_currency do
    Application.get_env(:ptax, :base_currency, :BRL)
  end
end
