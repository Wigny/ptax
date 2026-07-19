defmodule PTAX.ExchangeRates.HTTPClientMock do
  @base "https://www4.bcb.gov.br/Download/fechamento/"

  def get(url, _opts) do
    yesterday = Date.add(Date.utc_today(), -1)

    cond do
      url == @base <> Calendar.strftime(Date.utc_today(), "%Y%m%d") <> ".csv" ->
        {:error, {Money.ExchangeRateError, "404"}}

      url == @base <> Calendar.strftime(yesterday, "%Y%m%d") <> ".csv" ->
        {:ok,
         "#{Calendar.strftime(yesterday, "%d/%m/%Y")};220;A;USD;5,00000000;5,00000000;1,00000000;1,00000000\n"}

      url == @base <> "20260515.csv" ->
        {:ok,
         """
         15/05/2026;220;A;USD;5,06480000;5,06540000;1,00000000;1,00000000
         15/05/2026;540;B;GBP;6,75190000;6,75320000;1,33310000;1,33320000
         15/05/2026;978;B;EUR;5,88830000;5,89000000;1,16260000;1,16280000
         """}

      url == @base <> "20251225.csv" ->
        {:error, {Money.ExchangeRateError, "404"}}

      url == @base <> "20260101.csv" ->
        {:error, {Money.ExchangeRateError, inspect(:timeout)}}
    end
  end
end
