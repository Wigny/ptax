defmodule PTAXTest do
  use ExUnit.Case, async: true

  import Money.Sigil

  doctest PTAX

  @date ~D[2026-07-31]

  setup do
    Req.Test.stub(PTAX.Quotes, PTAX.Quotes.Stub)
  end

  describe "exchange/3" do
    test "converts the amount at the rate published for the date" do
      assert PTAX.exchange(~M[100]USD, :BRL, @date) == {:ok, ~M[507.6700000]BRL}
      assert PTAX.exchange(~M[100]BRL, :USD, @date) == {:ok, ~M[19.6955075]USD}
    end

    test "rounds only the converted amount, never the rate" do
      assert PTAX.exchange(~M[1]SCR, :FJD, @date) == {:ok, ~M[0.1586897]FJD}
      assert PTAX.exchange(~M[1000]SCR, :FJD, @date) == {:ok, ~M[158.6897080]FJD}
    end

    test "returns the original amount when the source and target currency are the same" do
      assert PTAX.exchange(~M[25]FJD, :FJD, @date) == {:ok, ~M[25.0000000]FJD}
    end
  end

  describe "unquoted currencies" do
    test "returns an error when the target currency is absent from the bulletin" do
      assert {:error, %PTAX.CurrencyNotQuotedError{} = error} =
               PTAX.exchange(~M[1]USD, :ZWL, @date)

      assert Exception.message(error) == "PTAX does not quote :ZWL"
    end

    test "returns an error when the source currency is absent from the bulletin" do
      assert {:error, %PTAX.CurrencyNotQuotedError{} = error} =
               PTAX.exchange(~M[1]ZWL, :USD, @date)

      assert Exception.message(error) == "PTAX does not quote :ZWL"
    end
  end

  describe "unavailable quotes" do
    test "returns an error when no bulletin was published for the date" do
      assert {:error, %PTAX.QuotesNotFoundError{} = error} =
               PTAX.exchange(~M[100]USD, :BRL, ~D[2025-12-25])

      assert Exception.message(error) == "no quotes published for 2025-12-25"
    end
  end

  describe "latest quotes" do
    test "falls back to the previous bulletin when today's has not been published" do
      today_bulletin = Calendar.strftime(Date.utc_today(), "/Download/fechamento/%Y%m%d.csv")

      Req.Test.stub(PTAX.Quotes, fn
        %{request_path: ^today_bulletin} = conn ->
          Plug.Conn.send_resp(conn, 404, "")

        conn ->
          Plug.Conn.send_resp(
            conn,
            200,
            "01/01/2026;220;A;USD;5,00000000;5,00000000;1,00000000;1,00000000"
          )
      end)

      assert PTAX.exchange(~M[100]USD, :BRL) == {:ok, ~M[500.0000000]BRL}
    end

    test "returns an error when the bulletin cannot be fetched" do
      Req.Test.stub(PTAX.Quotes, &Req.Test.transport_error(&1, :timeout))

      assert {:error, %Req.TransportError{} = error} = PTAX.exchange(~M[100]USD, :BRL)
      assert Exception.message(error) == "timeout"
    end

    test "returns an error when no bulletin was published in the last 7 days" do
      Req.Test.stub(PTAX.Quotes, fn conn -> Plug.Conn.send_resp(conn, 404, "") end)

      assert {:error, %PTAX.LatestQuotesNotFoundError{} = error} = PTAX.exchange(~M[100]USD, :BRL)
      assert Exception.message(error) == "no quotes published in the last 7 days"
    end
  end
end
