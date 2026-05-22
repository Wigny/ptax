defmodule PTAX.ExchangeRates.RetrieverMock do
  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.utc_today(), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end

  @url "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(Date.add(Date.utc_today(), -1), "%Y%m%d")}.csv"
  def retrieve_rates(@url, _config) do
    {:ok, %{BRL: Decimal.new("1"), USD: Decimal.new("0.2")}}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20260515.csv", config) do
    file = """
    15/05/2026;220;A;USD;5,06480000;5,06540000;1,00000000;1,00000000
    15/05/2026;540;B;GBP;6,75190000;6,75320000;1,33310000;1,33320000
    15/05/2026;978;B;EUR;5,88830000;5,89000000;1,16260000;1,16280000
    """

    {:ok, config.api_module.decode_rates(file)}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20251225.csv", _config) do
    {:error, {Money.ExchangeRateError, "404"}}
  end

  def retrieve_rates("https://www4.bcb.gov.br/Download/fechamento/20260101.csv", _config) do
    {:error, {Money.ExchangeRateError, ":timeout"}}
  end
end
