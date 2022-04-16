defmodule PTAX do
  @moduledoc """
  Gathers supported currency listing and conversion functions
  """

  alias PTAX.{Error, Money, Quotation, Requests}

  @type money :: Money.t()
  @type currency :: Money.currency()
  @type exchange_opts :: [to: currency, date: Date.t()] | %{to: currency, date: Date.t()}
  @type error :: Error.t()

  @doc """
  Returns a list of supported currencies

  ## Examples

      iex> PTAX.currencies()
      {:ok, ~w[BRL EUR GBP USD]a}
  """
  @spec currencies :: {:ok, list(currency)} | {:error, Error.t()}
  def currencies do
    result = Requests.get("/Moedas")

    with {:ok, response} <- Requests.response(result) do
      currencies = Enum.map(response, &String.to_atom(&1["simbolo"]))
      currencies = [:BRL | currencies]

      {:ok, Enum.sort(currencies)}
    end
  end

  @doc """
  Converts a value from one currency to another

  ## Examples

      iex> PTAX.exchange(PTAX.Money.new(5, :USD), to: :GBP, date: ~D[2021-12-24])
      {:ok, PTAX.Money.new("3.7297", :GBP)}

      iex> PTAX.exchange(PTAX.Money.new("546.56", :GBP), to: :USD, date: ~D[2021-12-24])
      {:ok, PTAX.Money.new("732.4997", :USD)}

      iex> PTAX.exchange(PTAX.Money.new("15.69", :EUR), to: :GBP, date: ~D[2021-12-24])
      {:ok, PTAX.Money.new("13.2474", :GBP)}
  """
  @spec exchange(money, opts :: exchange_opts) :: {:ok, money} | {:error, error}
  def exchange(money, opts) when is_list(opts) do
    exchange(money, Map.new(opts))
  end

  def exchange(money, %{to: to, date: date}) do
    with {:ok, %{pair: base_pair}} <- Quotation.get(money.currency, date),
         {:ok, %{pair: quoted_pair}} <- Quotation.get(to, date) do
      pair = Money.Pair.combine(base_pair, quoted_pair)
      value = Money.exchange(money, pair)

      {:ok, value}
    end
  end

  @doc """
  Similar to `exchange/2`, but throws an error if the amount cannot be converted.

  ## Examples

      iex> PTAX.exchange!(PTAX.Money.new(10, :USD), to: :BRL, date: ~D[2021-12-24])
      PTAX.Money.new("56.541", :BRL)

      iex> PTAX.exchange!(PTAX.Money.new("15.45", :USD), to: :GBP, date: ~D[2021-12-24])
      PTAX.Money.new("11.5247", :GBP)

      iex> PTAX.exchange!(PTAX.Money.new("15.45", :USD), to: :GBPS, date: ~D[2021-12-24])
      ** (PTAX.Error) Unknown error
  """
  @spec exchange!(money, opts :: exchange_opts) :: money
  def exchange!(money, opts) do
    case exchange(money, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
