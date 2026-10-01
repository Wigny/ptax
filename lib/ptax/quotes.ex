defmodule PTAX.Quotes do
  @moduledoc false

  @type quotation :: %{
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

  @spec fetch(Date.t()) :: {:ok, %{atom => quotation}} | {:error, Exception.t()}
  def fetch(%Date{} = date) do
    req_options = Application.get_env(:ptax, :req_options, [])

    url = "https://www4.bcb.gov.br/Download/fechamento/#{Calendar.strftime(date, "%Y%m%d")}.csv"
    cache_dir = :filename.basedir(:user_cache, ~c"ptax")

    Req.new()
    |> Req.Request.register_options([:cache_dir])
    |> Req.Request.append_request_steps(read_from_cache: &read_from_cache/1)
    |> Req.Request.append_response_steps(
      save_to_cache: &save_to_cache/1,
      decode_quotes: &decode_quotes/1
    )
    |> Req.get([url: url, cache_dir: cache_dir] ++ req_options)
    |> handle_response(date)
  end

  defp handle_response({:ok, %{status: 200, body: quotes}}, _date) do
    {:ok, quotes}
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

  defp read_from_cache(%{options: %{cache_dir: nil}} = request) do
    request
  end

  defp read_from_cache(request) do
    case File.read(filepath(request)) do
      {:ok, content} ->
        response =
          [status: 200, body: content]
          |> Req.Response.new()
          |> Req.Response.put_private(:cached, true)

        {request, response}

      {:error, _reason} ->
        request
    end
  end

  defp save_to_cache({%{options: %{cache_dir: nil}}, _response} = result) do
    result
  end

  defp save_to_cache({_request, %{private: %{cached: true}}} = result) do
    result
  end

  defp save_to_cache({request, %{status: 200} = response}) do
    write_atomically(filepath(request), response.body)

    {request, response}
  end

  defp save_to_cache(result) do
    result
  end

  defp write_atomically(path, content) do
    tmp_path = "#{path}.#{System.unique_integer([:positive])}"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(tmp_path, content),
         :ok <- File.rename(tmp_path, path) do
      :ok
    else
      _error -> File.rm(tmp_path)
    end
  end

  defp decode_quotes({request, %{status: 200, body: body} = response}) do
    body =
      body
      |> String.split(["\r\n", "\n"], trim: true)
      |> Enum.reduce(%{}, &parse_row/2)

    {request, %{response | body: body}}
  end

  defp decode_quotes({request, response}) do
    {request, response}
  end

  defp filepath(request) do
    Path.join(request.options.cache_dir, Path.basename(request.url.path))
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
