defmodule PTAX do
  @moduledoc """
  Documentation for `PTAX`.
  """

  alias PTAX.{Conversor, Moeda}

  @type converter_opts :: [
          de: Conversor.moeda(),
          para: Conversor.moeda(),
          data: Date.t() | nil,
          operacao: Conversor.operacao() | nil
        ]

  @spec moedas :: list(Moeda.t()) | {:error, term}
  defdelegate moedas, to: Moeda, as: :list

  @doc deletegate_to: {Conversor, :run, 2}
  @spec converter(
          valor :: Conversor.valor(),
          opts :: converter_opts | Conversor.opts()
        ) :: {:ok, Decimal.t()} | {:error, any}

  def converter(valor, opts) when is_list(opts) do
    today = "America/Sao_Paulo" |> DateTime.now!() |> DateTime.to_date()
    opts = Enum.into(opts, %{data: today, operacao: :venda})
    converter(valor, opts)
  end

  def converter(valor, opts) do
    Conversor.run(valor, opts)
  end

  @doc """
  Semelhante a `c:converter/2`, mas gera um error se o valor não puder ser convertido.

  ## Exemplo

      iex> PTAX.converter!(5, de: :USD, para: :BRL, data: ~D[2021-12-24], operacao: :compra)
      #Decimal<28.2705>
  """
  @spec converter!(
          valor :: Conversor.valor(),
          opts :: converter_opts | Conversor.opts()
        ) :: Decimal.t()

  def converter!(valor, opts) do
    case converter(valor, opts) do
      {:ok, result} -> result
      {:error, _error} -> raise "TODO"
    end
  end
end
