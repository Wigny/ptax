defmodule PTAX do
  @moduledoc """
  Gathers supported currency listing and conversion functions
  """

  alias PTAX.{Error, Money, Quotation, Requests}

  @typep money :: Money.t()
  @typep currency :: Money.currency()
  @typep operation :: :buy | :sell
  @typep exchange_opts ::
           [
             from: currency,
             to: currency,
             date: Date.t() | nil,
             operation: operation | nil,
             bulletin: Quotation.Bolletim.t() | nil
           ]
           | %{
               from: currency,
               to: currency,
               date: Date.t(),
               operation: operation,
               bulletin: Quotation.Bulletin.t()
             }
  @typep error :: Error.t()

  @doc """
  Returns a list of supported currencies

  ## Examples

      iex> PTAX.currencies()
      {:ok, ~w[GBP USD]a}
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

      iex> PTAX.exchange(PTAX.Money.new(5, :USD), to: :GBP, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      {:ok, PTAX.Money.new(3.7308, :GBP)}
  """

  @spec exchange(money, opts :: exchange_opts) :: {:ok, money} | {:error, error}
  def exchange(money, opts) when is_list(opts) do
    default_opts = %{
      date: "America/Sao_Paulo" |> Timex.now() |> Timex.to_date(),
      operation: :sell,
      bulletin: Quotation.Bulletin.Closing
    }

    opts = Enum.into(opts, default_opts)
    exchange(money, opts)
  end

  def exchange(%{currency: :BRL} = money, %{to: currency} = opts) do
    %{date: date, operation: operation, bulletin: bulletin} = opts

    with {:ok, quotation} <- Quotation.get(currency, date, bulletin) do
      %{^operation => rate} = quotation
      {:ok, Money.exchange!(money, to: currency, rate: rate)}
    end
  end

  def exchange(%{currency: currency} = money, %{to: :BRL} = opts) do
    %{date: date, operation: operation, bulletin: bulletin} = opts

    with {:ok, quotation} <- Quotation.get(currency, date, bulletin) do
      %{^operation => rate} = quotation
      {:ok, Money.exchange!(money, to: :BRL, rate: rate)}
    end
  end

  def exchange(money, opts) when is_map(opts) do
    with {:ok, base_money} <- exchange(money, %{opts | to: :BRL}) do
      exchange(base_money, opts)
    end
  end

  @doc """
  Similar to `exchange/2`, but throws an error if the amount cannot be converted.

  ## Examples

      iex> PTAX.exchange!(PTAX.Money.new(15, :USD), to: :BRL, date: ~D[2021-12-24], operation: :buy, bulletin: PTAX.Quotation.Bulletin.Closing)
      PTAX.Money.new(84.8115, :BRL)

      iex> PTAX.exchange!(PTAX.Money.new(15.45, :USD), to: :GBP, date: ~D[2021-12-24])
      PTAX.Money.new(11.5247, :GBP)

      iex> PTAX.exchange!(PTAX.Money.new(15.45, :USD), to: :GBPS, date: ~D[2021-12-24])
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
