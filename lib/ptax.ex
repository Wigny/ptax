defmodule PTAX do
  @moduledoc """
  Gathers supported currency listing and conversion functions
  """

  alias PTAX.{Error, Money, Quotation, Requests}

  @typep money :: Money.t()
  @typep currency :: Money.currency()
  @typep exchange_opts ::
           [from: currency, to: currency, date: Date.t()]
           | %{from: currency, to: currency, date: Date.t()}
  @typep error :: Error.t()

  @doc """
  Returns a list of supported currencies

  ## Examples

      iex> PTAX.currencies()
      {:ok, ~w[GBP EUR USD]a}
  """
  @spec currencies :: {:ok, list(currency)} | {:error, Error.t()}
  def currencies do
    result = Requests.get("/Moedas")

    with {:ok, response} <- Requests.response(result) do
      currencies = Enum.map(response, &String.to_atom(&1["simbolo"]))

      {:ok, currencies}
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

  def exchange(%{currency: :BRL} = money, %{to: currency, date: date}) do
    with {:ok, %{ask: rate}} <- Quotation.get(currency, date) do
      {:ok, money |> Money.exchange!(to: currency, rate: rate) |> Money.normalize()}
    end
  end

  def exchange(%{currency: currency} = money, %{to: :BRL, date: date}) do
    with {:ok, %{bid: rate}} <- Quotation.get(currency, date) do
      {:ok, money |> Money.exchange!(to: :BRL, rate: rate) |> Money.normalize()}
    end
  end

  def exchange(%{currency: :USD} = money, %{to: currency, date: date}) do
    with {:ok, %{pairs: pairs}} <- Quotation.get(currency, date) do
      pair = if pairs.type == :A, do: pairs.bid, else: pairs.ask
      {:ok, money |> Money.exchange!(pair) |> Money.normalize()}
    end
  end

  def exchange(%{currency: currency} = money, %{to: :USD, date: date}) do
    with {:ok, %{pairs: pairs}} <- Quotation.get(currency, date) do
      pair = if pairs.type == :A, do: pairs.ask, else: pairs.bid
      {:ok, money |> Money.exchange!(pair) |> Money.normalize()}
    end
  end

  def exchange(money, %{to: to, date: date}) do
    with {:ok, %{pairs: base_pairs}} <- Quotation.get(money.currency, date),
         {:ok, %{pairs: quoted_pairs}} <- Quotation.get(to, date) do
      quoted_pair =
        if base_pairs.type == quoted_pairs.type,
          do: quoted_pairs.ask,
          else: quoted_pairs.bid

      value =
        money
        |> Money.exchange!(base_pairs.bid)
        |> Money.exchange!(quoted_pair)
        |> Money.normalize()

      {:ok, value}
    end
  end

  @doc """
  Similar to `exchange/2`, but throws an error if the amount cannot be converted.

  ## Examples

      iex> PTAX.exchange!(PTAX.Money.new(15, :USD), to: :BRL, date: ~D[2021-12-24])
      PTAX.Money.new("84.8115", :BRL)

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
