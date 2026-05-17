defmodule PTAX.ExchangeRates do
  @moduledoc false

  @behaviour Money.ExchangeRates

  @retriever Application.compile_env(:ptax, :retriever, Money.ExchangeRates.Retriever)

  @impl true

  def get_latest_rates(config) do
    get_nearest_historic_rates(Date.utc_today(), 0, config)
  end

  defp get_nearest_historic_rates(_date, 7, _config) do
    {:error, {Money.ExchangeRateError, "no rates found in the last 7 days"}}
  end

  defp get_nearest_historic_rates(date, attempts, config) do
    with {:error, {Money.ExchangeRateError, "404"}} <- get_historic_rates(date, config) do
      get_nearest_historic_rates(Date.add(date, -1), attempts + 1, config)
    end
  end

  @impl true
  def get_historic_rates(date, config) do
    url = "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(date, "%Y%m%d")}.csv"

    with {:ok, rates} <- @retriever.retrieve_rates(url, config) do
      {:ok, Map.put(rates, :BRL, Decimal.new("1"))}
    end
  end

  @impl true
  def decode_rates(body) when is_binary(body) do
    body
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      [_date, _code, _type, currency, bid, _ask, _par_bid, _par_ask] = String.split(line, ";")

      case Money.new(currency, bid, locale: "pt-BR") do
        %Money{} = rate -> Map.put(acc, rate.currency, rate.amount)
        {:error, _reason} -> acc
      end
    end)
  end
end
