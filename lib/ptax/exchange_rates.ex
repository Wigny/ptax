defmodule PTAX.ExchangeRates do
  @moduledoc """
  An `ex_money` exchange rate backend backed by Brazil's Central Bank (BCB)
  PTAX daily closing CSV feed.

  Configure it as the `ex_money` API module in your application:

      config :ex_money, api_module: PTAX.ExchangeRates

  Once set, `ex_money` will call this module to populate its rate cache.
  """

  @behaviour Money.ExchangeRates

  @retriever Application.compile_env(:ptax, :retriever, Money.ExchangeRates.Retriever)

  @impl true
  @doc false
  def get_latest_rates(config) do
    get_nearest_historic_rates(Date.utc_today(), 0, config)
  end

  defp get_nearest_historic_rates(_date, 7, _config) do
    {:error, {Money.ExchangeRateError, "no rates found in the last 7 days"}}
  end

  defp get_nearest_historic_rates(date, attempts, config) do
    with {:error, {Money.ExchangeRateError, "404"}} <- fetch_rates(date, config) do
      get_nearest_historic_rates(Date.add(date, -1), attempts + 1, config)
    end
  end

  @impl true
  @doc false
  def get_historic_rates(date, config) do
    with {:error, {Money.ExchangeRateError, "404"}} <- fetch_rates(date, config) do
      {:error, {Money.ExchangeRateError, "no exchange rates available for #{date}"}}
    end
  end

  defp fetch_rates(date, config) do
    url = "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(date, "%Y%m%d")}.csv"
    @retriever.retrieve_rates(url, config)
  end

  @impl true
  @doc false
  def decode_rates(body) when is_binary(body) do
    body
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{BRL: Decimal.new("1")}, fn line, acc ->
      [_date, _code, _type, currency, bid, ask, _par_bid, _par_ask] = String.split(line, ";")

      case Money.validate_currency(currency) do
        {:ok, currency} ->
          ask = Decimal.new(String.replace(ask, ",", "."))
          bid = Decimal.new(String.replace(bid, ",", "."))
          mid = Decimal.div(Decimal.add(ask, bid), 2)

          Map.put(acc, currency, Decimal.div(Decimal.new("1"), mid))

        {:error, _reason} ->
          acc
      end
    end)
  end
end
