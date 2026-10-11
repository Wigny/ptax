defmodule PTAX.Quotes do
  @moduledoc false

  @type quote :: %{
          type: :direct | :indirect,
          bid: Decimal.t(),
          ask: Decimal.t(),
          bid_parity: Decimal.t(),
          ask_parity: Decimal.t()
        }

  @publish_time ~T[13:00:00]

  @spec publish_dates(DateTime.t()) :: Enumerable.t(Date.t())
  def publish_dates(%DateTime{time_zone: "America/Sao_Paulo"} = from) do
    before_publish? = Time.before?(from, @publish_time)

    from
    |> Date.add((before_publish? && -1) || 0)
    |> Stream.iterate(&Date.add(&1, -1))
    |> Stream.reject(&(Date.day_of_week(&1) > 5))
    |> Stream.reject(&PTAX.Holidays.holiday?/1)
  end

  @spec fetch(Date.t()) :: {:ok, %{atom => quote}} | {:error, Exception.t()}
  def fetch(%Date{} = date) do
    req_options = Application.get_env(:ptax, :req_options, [])

    url = "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(date, "%Y%m%d")}.csv"

    Req.new()
    |> PTAX.Quotes.FileCache.attach()
    |> Req.get([url: url] ++ req_options)
    |> handle_response(date)
  end

  defp handle_response({:ok, %{status: 200, body: body}}, _date) do
    {:ok, parse_quotes(body)}
  end

  defp handle_response({:ok, %{status: 404}}, date) do
    {:error, PTAX.QuotesNotFoundError.exception(date: date)}
  end

  defp handle_response({:ok, %{status: status}}, _date) do
    {:error, PTAX.UnexpectedResponseError.exception(status: status)}
  end

  defp handle_response({:error, exception}, _date) do
    {:error, exception}
  end

  defp parse_quotes(body) do
    body
    |> String.split(["\r\n", "\n"], trim: true)
    |> Enum.reduce(%{}, &parse_row/2)
  end

  defp parse_row(row, acc) do
    [_date, _code, type, currency, bid, ask, bid_parity, ask_parity] = String.split(row, ";")

    if currency = parse_currency(currency) do
      Map.put(acc, currency, %{
        type: parse_type(type),
        bid: parse_decimal(bid),
        ask: parse_decimal(ask),
        bid_parity: parse_decimal(bid_parity),
        ask_parity: parse_decimal(ask_parity)
      })
    else
      acc
    end
  end

  defp parse_currency(currency) do
    case Money.validate_currency(currency) do
      {:ok, currency} -> currency
      {:error, {Money.UnknownCurrencyError, _message}} -> nil
    end
  end

  defp parse_type("A"), do: :indirect
  defp parse_type("B"), do: :direct
  defp parse_decimal(value), do: Decimal.new(String.replace(value, ",", "."))
end
