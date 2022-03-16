defmodule PTAX do
  @moduledoc """
  Gathers supported currency listing and conversion functions
  """

  alias PTAX.{Converter, Quotation, Error, Currency}

  @type amount :: Decimal.decimal()
  @type currency :: atom()
  @type operation :: :buy | :sell

  @typep convert_opts ::
           Converter.opts()
           | [
               from: currency,
               to: currency,
               date: Date.t() | nil,
               operation: operation | nil,
               bulletin: Quotation.Bolletim.t() | nil
             ]

  @spec currencies :: {:ok, list(Currency.t())} | {:error, Error.t()}
  defdelegate currencies, to: Currency, as: :list

  @doc """
  Converts a value from one currency to another

  ## Example

      iex> PTAX.convert(5, from: :USD, to: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      {:ok, #Decimal<28.2705>}
  """
  @spec convert(amount :: amount, opts :: convert_opts) :: {:ok, amount} | {:error, Error.t()}
  def convert(amount, opts) when is_list(opts) do
    default_opts = %{
      date: "America/Sao_Paulo" |> Timex.now() |> Timex.to_date(),
      operation: :sell,
      bulletin: Quotation.Bulletin.Closing
    }

    opts = Enum.into(opts, default_opts)
    convert(amount, opts)
  end

  def convert(amount, opts) when is_map(opts) do
    Converter.run(amount, opts)
  end

  @doc """
  Similar to `convert/2`, but throws an error if the amount cannot be converted.

  ## Example

      iex> PTAX.convert!(5, from: :USD, to: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      #Decimal<28.2705>
  """
  @spec convert!(amount :: amount, opts :: convert_opts) :: amount
  def convert!(amount, opts) do
    case convert(amount, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
