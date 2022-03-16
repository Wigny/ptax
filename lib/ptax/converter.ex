defmodule PTAX.Converter do
  @moduledoc "Gathers currency conversion functions"

  alias PTAX.{Quotation, Error}

  @type opts :: %{
          from: PTAX.currency(),
          to: PTAX.currency(),
          date: Date.t(),
          operation: PTAX.operation(),
          bulletin: Quotation.Bulletin.t()
        }

  defguardp valid_operation?(operation) when operation in ~w[buy sell]a
  defguardp valid_currency?(currency) when is_atom(currency)
  defguardp is_base?(currency) when currency == :BRL

  defguardp valid_params?(opts)
            when valid_operation?(opts.operation) and
                   valid_currency?(opts.from) and
                   valid_currency?(opts.to)

  defguardp has_base?(opts) when is_base?(opts.from) or is_base?(opts.to)

  @doc """
  Convert a value from one currency to another

  ## Example

      iex> PTAX.Converter.run(15, %{from: :BRL, to: :GBP, date: ~D[2021-12-24], operation: :sell, bulletin: PTAX.Quotation.Bulletin.Closing})
      {:ok, #Decimal<1.9772>}
      iex> PTAX.Converter.run(5, %{from: :USD, to: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing})
      {:ok, #Decimal<28.2705>}
  """
  @spec run(amount :: PTAX.amount(), opts :: opts) :: {:ok, PTAX.amount()} | {:error, Error.t()}

  def run(amount, opts) when valid_params?(opts) and has_base?(opts) do
    %{from: from, to: to, date: date, operation: operation, bulletin: bulletin} = opts
    {quote_currency, base_conversor} = quote_currency([from, to])

    with {:ok, %{^operation => rate}} <- Quotation.get(quote_currency, date, bulletin) do
      base_currency = apply(Decimal, base_conversor, [amount, rate])

      result = base_currency |> Decimal.round(4) |> Decimal.normalize()
      {:ok, result}
    end
  end

  def run(amount, opts) when valid_params?(opts) do
    with {:ok, amount_brl} <- run(amount, %{opts | to: :BRL}) do
      run(amount_brl, %{opts | from: :BRL})
    end
  end

  defp quote_currency(currencies)
  defp quote_currency([:BRL, currency]), do: {currency, :div}
  defp quote_currency([currency, :BRL]), do: {currency, :mult}
end
