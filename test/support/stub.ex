defmodule PTAX.Quotes.Stub do
  @moduledoc false

  @behaviour Plug

  @unpublished "20251225.csv"
  @bulletin "20260731.csv"

  @impl true
  def init(options), do: options

  @impl true
  def call(conn, _options) do
    case Path.basename(conn.request_path) do
      @unpublished -> Plug.Conn.send_resp(conn, 404, "")
      _filename -> Plug.Conn.send_file(conn, 200, Path.join(__DIR__, @bulletin))
    end
  end
end
