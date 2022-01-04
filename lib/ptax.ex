defmodule PTAX do
  @moduledoc """
  Agrega funções de listagem e conversão de moedas suportadas
  """

  alias PTAX.{Converter, Quotation, Error, Currency}

  @type currency :: atom()
  @type amount :: Decimal.decimal()

  @type converter_opts :: [
          de: Converter.moeda(),
          para: Converter.moeda(),
          date: Date.t() | nil,
          operation: Converter.operation() | nil,
          bulletin: Quotation.Boletim.t() | nil
        ]

  @spec moedas :: list(Currency.t()) | {:error, Error.t()}
  defdelegate moedas, to: Currency, as: :list

  @doc """
  Converte um valor de uma moeda para outra

  ## Example

      iex> PTAX.converter(5, de: :USD, para: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      {:ok, #Decimal<28.2705>}
  """
  @spec converter(
          valor :: Converter.valor(),
          opts :: converter_opts | Converter.opts()
        ) :: {:ok, Decimal.t()} | {:error, Error.t()}

  def converter(valor, opts) when is_list(opts) do
    default_opts = %{
      date: "America/Sao_Paulo" |> Timex.now() |> Timex.to_date(),
      operation: :sell,
      bulletin: Quotation.Bulletin.Closing
    }

    opts = Enum.into(opts, default_opts)
    converter(valor, opts)
  end

  def converter(valor, opts) do
    Converter.run(valor, opts)
  end

  @doc """
  Semelhante a `converter/2`, mas gera um erro se o valor não puder ser convertido.

  ## Example

      iex> PTAX.converter!(5, de: :USD, para: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      #Decimal<28.2705>
  """
  @spec converter!(
          valor :: Converter.valor(),
          opts :: converter_opts | Converter.opts()
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
