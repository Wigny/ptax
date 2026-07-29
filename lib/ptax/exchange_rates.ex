defmodule PTAX.ExchangeRates do
  @moduledoc false

  @behaviour Money.ExchangeRates

  @req_options Application.compile_env(:ptax, :req_options, [])

  @impl true
  def get_latest_rates(config) do
    today = Date.utc_today()

    Enum.find_value(
      Date.range(today, Date.add(today, -6), -1),
      {:error, {Money.ExchangeRateError, "no rates found in the last 7 days"}},
      fn date ->
        not_found_message = "no exchange rates available for #{date}"

        with {:error, {Money.ExchangeRateError, ^not_found_message}} <-
               get_historic_rates(date, config),
             do: nil
      end
    )
  end

  @impl true
  def get_historic_rates(date, config) do
    %{quote_side: quote_side} = config.retriever_options

    options = [
      url: "https://www4.bcb.gov.br/Download/fechamento/:date.csv",
      path_params: [date: Calendar.strftime(date, "%Y%m%d")],
      max_retries: 2,
      retry_delay: to_timeout(millisecond: 200)
    ]

    case Req.get(options ++ @req_options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, decode_rates(body, quote_side)}

      {:ok, %Req.Response{status: 404}} ->
        {:error, {Money.ExchangeRateError, "no exchange rates available for #{date}"}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {Money.ExchangeRateError, "unexpected response status #{status}"}}

      {:error, exception} ->
        {:error, {Money.ExchangeRateError, Exception.message(exception)}}
    end
  end

  defp decode_rates(body, quote_side) do
    body
    |> String.split(["\r\n", "\n"], trim: true)
    |> Enum.reduce(%{BRL: Decimal.new("1")}, fn line, acc ->
      [_date, _code, _type, currency, bid, ask, _par_bid, _par_ask] = String.split(line, ";")

      case Money.validate_currency(currency) do
        {:ok, currency} ->
          rate = rate(bid, ask, quote_side)
          Map.put(acc, currency, Decimal.div(Decimal.new("1"), rate))

        {:error, {Money.UnknownCurrencyError, _message}} ->
          acc
      end
    end)
  end

  defp rate(bid, _ask, :bid), do: Decimal.new(String.replace(bid, ",", "."))
  defp rate(_bid, ask, :ask), do: Decimal.new(String.replace(ask, ",", "."))
end
