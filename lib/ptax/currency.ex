defmodule PTAX.Currency do
  @moduledoc "Defines the structure of a currency"

  use TypedStruct
  alias PTAX.Requests

  typedstruct enforce: true do
    field :name, binary()
    field :symbol, PTAX.currency()
  end

  @doc """
  Returns a list of supported currencies

  ## Example

      iex> PTAX.Currency.list()
      {:ok, [%PTAX.Currency{name: "Euro", symbol: :EUR}, %PTAX.Currency{name: "Pound Sterling", symbol: :GBP}]}
  """
  @spec list :: {:ok, list(t)} | {:error, PTAX.Error.t()}
  def list do
    result = Requests.get("/Moedas")

    with {:ok, value} <- Requests.response(result) do
      result = Enum.map(value, &parse/1)

      {:ok, result}
    end
  end

  defp parse(%{"nome_formatado" => name, "simbolo" => symbol}) do
    params = %{
      name: Gettext.dgettext(PTAX.Gettext, "currencies", name),
      symbol: String.to_atom(symbol)
    }

    struct!(__MODULE__, params)
  end
end
