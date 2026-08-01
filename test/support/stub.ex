defmodule PTAX.Quotes.Stub do
  @moduledoc false

  @behaviour Plug

  @impl true
  def init(options), do: options

  @impl true
  def call(conn, _options) do
    path = Path.join(__DIR__, Path.basename(conn.request_path))

    if File.exists?(path) do
      Plug.Conn.send_file(conn, 200, path)
    else
      Plug.Conn.send_resp(conn, 404, "")
    end
  end
end
