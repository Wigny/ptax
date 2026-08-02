defmodule PTAX.Quotes.Stub do
  @moduledoc false

  @behaviour Plug

  @impl true
  def init(options), do: options

  @bulletin "20260731.csv"

  @impl true
  def call(conn, _options) do
    yesterday = Date.add(Date.utc_today(), -1)
    yesterday_bulletin = Calendar.strftime(yesterday, "%Y%m%d.csv")

    case Path.basename(conn.request_path) do
      @bulletin ->
        Plug.Conn.send_file(conn, 200, Path.join(__DIR__, @bulletin))

      # No fixture can be named after a date that moves, so the latest quotes get a single row.
      ^yesterday_bulletin ->
        Plug.Conn.send_resp(
          conn,
          200,
          "#{Calendar.strftime(yesterday, "%d/%m/%Y")};220;A;USD;5,00000000;5,00000000;1,00000000;1,00000000"
        )

      _bulletin ->
        Plug.Conn.send_resp(conn, 404, "")
    end
  end
end
