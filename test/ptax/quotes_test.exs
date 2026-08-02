defmodule PTAX.QuotesTest do
  use ExUnit.Case, async: true

  alias PTAX.Quotes

  setup do
    Req.Test.stub(PTAX.Quotes, PTAX.Quotes.Stub)
  end

  describe "fetch/1" do
    test "returns quotes for every known currency in the bulletin" do
      assert {:ok, quotes} = Quotes.fetch(~D[2026-07-31])

      assert map_size(quotes) == 156

      assert quotes[:BRL] == %{
               ask: Decimal.new("1"),
               bid: Decimal.new("1"),
               ask_parity: nil,
               bid_parity: nil,
               type: :base
             }

      assert quotes[:EUR] == %{
               ask: Decimal.new("5.84900000"),
               bid: Decimal.new("5.84730000"),
               ask_parity: Decimal.new("1.15200000"),
               bid_parity: Decimal.new("1.15180000"),
               type: :direct
             }

      assert quotes[:USD] == %{
               ask: Decimal.new("5.07730000"),
               bid: Decimal.new("5.07670000"),
               ask_parity: Decimal.new("1.00000000"),
               bid_parity: Decimal.new("1.00000000"),
               type: :indirect
             }

      refute Map.has_key?(quotes, :SDR)
    end

    test "returns an error when BCB published nothing for the date" do
      assert Quotes.fetch(~D[2025-12-25]) ==
               {:error, %PTAX.QuotesNotFoundError{date: ~D[2025-12-25]}}
    end

    test "returns an error when BCB responds with an unexpected status" do
      Req.Test.stub(PTAX.Quotes, &Plug.Conn.send_resp(&1, 503, ""))

      assert {:error, %PTAX.UnexpectedResponseError{} = error} = Quotes.fetch(~D[2026-07-31])
      assert Exception.message(error) == "BCB responded with an unexpected status: 503"
    end

    test "returns an error when the request fails" do
      Req.Test.stub(PTAX.Quotes, &Req.Test.transport_error(&1, :closed))

      assert {:error, %Req.TransportError{reason: :closed}} = Quotes.fetch(~D[2026-07-31])
    end
  end

  describe "caching" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      req_options = Application.get_env(:ptax, :req_options)

      Application.put_env(:ptax, :req_options, Keyword.put(req_options, :cache_dir, tmp_dir))

      on_exit(fn -> Application.put_env(:ptax, :req_options, req_options) end)
    end

    test "writes the fetched bulletin to a cache file", %{tmp_dir: tmp_dir} do
      assert {:ok, _quotes} = Quotes.fetch(~D[2026-07-31])

      assert File.exists?(Path.join(tmp_dir, "20260731.csv"))
    end

    test "reads from the cached file instead of fetching the bulletin it again",
         %{tmp_dir: tmp_dir} do
      File.write!(
        Path.join(tmp_dir, "20260730.csv"),
        "30/07/2026;220;A;USD;5,00000000;5,10000000;1,00000000;1,00000000"
      )

      assert {:ok, quotes} = Quotes.fetch(~D[2026-07-30])
      assert Map.has_key?(quotes, :USD)
    end

    test "serves the bulletin when it cannot be cached", %{tmp_dir: tmp_dir} do
      File.chmod!(tmp_dir, 0o555)
      on_exit(fn -> File.chmod!(tmp_dir, 0o755) end)

      assert {:ok, _quotes} = Quotes.fetch(~D[2026-07-31])
      refute File.exists?(Path.join(tmp_dir, "20260731.csv"))
    end

    test "fetches the bulletin when the cached file cannot be read", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "20260731.csv")

      File.write!(path, "31/07/2026;220;A;USD;9,99000000;9,99000000;1,00000000;1,00000000")
      File.chmod!(path, 0o000)

      assert {:ok, quotes} = Quotes.fetch(~D[2026-07-31])
      assert quotes[:USD].bid == Decimal.new("5.07670000")
    end

    test "serves a read-only cached file", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "20260730.csv")

      File.write!(path, "30/07/2026;220;A;USD;5,00000000;5,10000000;1,00000000;1,00000000")
      File.chmod!(path, 0o444)

      assert {:ok, _quotes} = Quotes.fetch(~D[2026-07-30])
    end
  end
end
