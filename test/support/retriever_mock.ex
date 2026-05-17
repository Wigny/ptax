defmodule PTAX.ExchangeRates.RetrieverMock do
  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.utc_today(), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end

  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.add(Date.utc_today(), -1), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:ok, %{USD: Decimal.new("5")}}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20260515.csv", _config) do
    {:ok, %{GBP: Decimal.new("6.75190000"), USD: Decimal.new("5.06480000")}}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20251225.csv", _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end
end
