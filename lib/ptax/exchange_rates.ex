defmodule PTAX.ExchangeRates do
  @moduledoc false

  @behaviour Money.ExchangeRates

  @http_client Application.compile_env(:ptax, :http_client, Money.ExchangeRates.HTTP)

  @impl true
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
  def get_historic_rates(date, config) do
    with {:error, {Money.ExchangeRateError, "404"}} <- fetch_rates(date, config) do
      {:error, {Money.ExchangeRateError, "no exchange rates available for #{date}"}}
    end
  end

  defp fetch_rates(date, config) do
    url = "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(date, "%Y%m%d")}.csv"

    with {:ok, body} when is_binary(body) <-
           @http_client.get(url, verify_peer: config.verify_peer) do
      {:ok, decode_rates(body, config.retriever_options)}
    end
  end

  defp decode_rates(body, options) do
    body
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{BRL: Decimal.new("1")}, fn line, acc ->
      [_date, _code, _type, currency, bid, ask, _par_bid, _par_ask] = String.split(line, ";")

      case Money.validate_currency(currency) do
        {:ok, currency} ->
          rate = rate(bid, ask, options)
          Map.put(acc, currency, Decimal.div(Decimal.new("1"), rate))

        {:error, {Money.UnknownCurrencyError, _message}} ->
          acc
      end
    end)
  end

  defp rate(bid, _ask, %{quote_side: :bid}), do: Decimal.new(String.replace(bid, ",", "."))
  defp rate(_bid, ask, %{quote_side: :ask}), do: Decimal.new(String.replace(ask, ",", "."))
end
