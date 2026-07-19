defmodule PTAX.ExchangeRates.Cache do
  @moduledoc false

  @behaviour Money.ExchangeRates.Cache

  @ets_table :ptax_exchange_rates

  @impl true
  def init do
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :protected])
    else
      @ets_table
    end
  end

  @impl true
  def store_historic_rates(rates, date) do
    :ets.insert(@ets_table, {date, rates})
    :ok
  end

  @impl true
  def historic_rates(date) do
    case :ets.lookup(@ets_table, date) do
      [{^date, rates}] ->
        {:ok, rates}

      [] ->
        {:error,
         {Money.ExchangeRateError, "No exchange rates for #{Date.to_string(date)} were found"}}
    end
  end

  @impl true
  def store_latest_rates(rates, retrieved_at) do
    :ets.insert(@ets_table, {:latest_rates, rates})
    :ets.insert(@ets_table, {:last_updated, retrieved_at})
    :ok
  end

  @impl true
  def latest_rates do
    case :ets.lookup(@ets_table, :latest_rates) do
      [{:latest_rates, rates}] -> {:ok, rates}
      [] -> {:error, {Money.ExchangeRateError, "No exchange rates were found"}}
    end
  end

  @impl true
  def last_updated do
    case :ets.lookup(@ets_table, :last_updated) do
      [{:last_updated, last_updated}] -> {:ok, last_updated}
      [] -> {:error, {Money.ExchangeRateError, "Last updated date is not known"}}
    end
  end

  @impl true
  def terminate do
    :ok
  end
end
