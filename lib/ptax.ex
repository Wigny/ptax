defmodule PTAX do
  @moduledoc """
  Documentation for `PTAX`.
  """

  alias PTAX.{Conversor, Moeda}

  @spec moedas :: list(Moeda.t()) | {:error, term}
  defdelegate moedas, to: Moeda, as: :list

  def converter(valor, opts) when is_list(opts) do
    today = "America/Sao_Paulo" |> DateTime.now!() |> DateTime.to_date()
    opts = Enum.into(opts, %{data: today, operacao: :venda})
    converter(valor, opts)
  end

  def converter(valor, opts) do
    Conversor.run(valor, opts)
  end

  def converter!(valor, opts) do
    case converter(valor, opts) do
      {:ok, result} -> result
      {:error, _error} -> raise "TODO"
    end
  end
end
