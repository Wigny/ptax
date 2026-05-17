defmodule PTAX.ExchangeRates.RetrieverMock do
  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.utc_today(), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end

  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.add(Date.utc_today(), -1), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:ok,
     %{
       BRL: Decimal.new("1"),
       USD: Decimal.new("0.2")
     }}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20260515.csv", _config) do
    {:ok,
     %{
       BRL: Decimal.new("1"),
       EUR: Decimal.new("0.169803791718669077880509071767572"),
       GBP: Decimal.new("0.148092202205092890833833144515775"),
       USD: Decimal.new("0.197429468322441807664211960277191")
     }}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20251225.csv", _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end
end
