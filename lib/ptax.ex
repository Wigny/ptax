defmodule PTAX do
  @moduledoc """
  Documentation for `PTAX`.
  """

  alias PTAX.{Cotacao, Moeda}

  @spec moedas :: list(Moeda.t()) | {:error, term}
  defdelegate moedas, to: Moeda, as: :list

  @spec converter(
          valor :: pos_integer | Decimal.t(),
          moedas :: [de: binary, para: binary],
          data :: Date.t(),
          operacao :: :venda | :compra
        ) :: {:ok, Decimal.t()} | {:error, term}

  def converter(
        valor,
        moedas \\ [de: "BRL", para: "USD"],
        data \\ "America/Sao_Paulo" |> DateTime.now!() |> DateTime.to_date(),
        operacao \\ :venda
      )

  def converter(valor, [de: de, para: "BRL"], data, operacao) do
    with {:ok, %{^operacao => cotacao}} <- Cotacao.get(de, data) do
      result =
        valor
        |> Decimal.mult(cotacao)
        |> Decimal.round(4)
        |> Decimal.normalize()

      {:ok, result}
    end
  end

  def converter(valor, [de: "BRL", para: para], data, operacao) do
    with {:ok, %{^operacao => cotacao}} <- Cotacao.get(para, data) do
      result =
        valor
        |> Decimal.div(cotacao)
        |> Decimal.round(4)
        |> Decimal.normalize()

      {:ok, result}
    end
  end

  def converter(valor, [de: de, para: para], data, operacao) do
    with {:ok, valor_brl} <- converter(valor, [de: de, para: "BRL"], data, operacao) do
      converter(valor_brl, [de: "BRL", para: para], data, operacao)
    end
  end

  @spec converter!(
          valor :: pos_integer | Decimal.t(),
          moedas :: [de: binary, para: binary],
          data :: Date.t(),
          operacao :: :venda | :compra
        ) :: Decimal.t()

  def converter!(
        valor,
        moedas \\ [de: "BRL", para: "USD"],
        data \\ "America/Sao_Paulo" |> DateTime.now!() |> DateTime.to_date(),
        operacao \\ :venda
      )

  def converter!(valor, moedas, data, operacao) do
    case converter(valor, moedas, data, operacao) do
      {:ok, result} -> result
      {:error, _error} -> raise "TODO"
    end
  end
end
