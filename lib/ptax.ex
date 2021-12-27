defmodule PTAX do
  @moduledoc """
  Documentation for `PTAX`.
  """

  alias PTAX.{Cotacao, Moeda}

  defdelegate moedas, to: Moeda, as: :list

  @spec converter(
          valor :: pos_integer | Decimal.t(),
          moedas :: [de: binary, para: binary],
          operacao :: :venda | :compra,
          data :: Date.t()
        ) :: Decimal.t() | nil

  def converter(
        valor,
        moedas \\ [de: "BRL", para: "USD"],
        operacao \\ :venda,
        data \\ "America/Sao_Paulo" |> DateTime.now!() |> DateTime.to_date()
      )

  def converter(valor, [de: de, para: "BRL"], operacao, data) do
    with %{^operacao => cotacao} <- Cotacao.get(de, data) do
      Decimal.mult(valor, cotacao)
    end
  end

  def converter(valor, [de: "BRL", para: para], operacao, data) do
    with %{^operacao => cotacao} <- Cotacao.get(para, data) do
      valor
      |> Decimal.div(cotacao)
      |> Decimal.round(4)
    end
  end

  def converter(valor, [de: de, para: para], operacao, data) do
    if valor_brl = converter(valor, [de: de, para: "BRL"], operacao, data) do
      converter(valor_brl, [de: "BRL", para: para], operacao, data)
    end
  end
end
