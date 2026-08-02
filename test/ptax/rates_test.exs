defmodule PTAX.RatesTest do
  use ExUnit.Case, async: true

  alias PTAX.Rates

  @date ~D[2026-07-31]

  setup do
    Req.Test.stub(PTAX.Quotes, PTAX.Quotes.Stub)
  end

  describe "same-currency rates" do
    test "quotes a currency into itself as 1" do
      assert rate(:BRL, :BRL) == Decimal.new("1")
      assert rate(:SCR, :SCR) == Decimal.new("1")
      assert rate(:FJD, :FJD) == Decimal.new("1")
    end
  end

  describe "BRL rates" do
    test "quotes a foreign currency into BRL at its buy rate" do
      assert rate(:SCR, :BRL) == Decimal.new("0.33430000")
      assert rate(:FJD, :BRL) == Decimal.new("2.26320000")
      assert rate(:USD, :BRL) == Decimal.new("5.07670000")
    end

    test "quotes BRL into a foreign currency at the inverse of its sell rate" do
      assert rate(:BRL, :SCR) == Decimal.new("2.783964365256124721603563474387528")
      assert rate(:BRL, :FJD) == Decimal.new("0.4310716441072506250538839555134063")
      assert rate(:BRL, :USD) == Decimal.new("0.1969550745474957162271285919681721")
    end
  end

  describe "USD rates" do
    test "quotes an indirect-quote currency into USD at the inverse of its ask parity" do
      assert rate(:SCR, :USD) == Decimal.new("0.06584015327587682624125148963346787")
    end

    test "quotes USD into an indirect-quote currency at its bid parity" do
      assert rate(:USD, :SCR) == Decimal.new("14.13550000")
      assert rate(:USD, :JPY) == Decimal.new("159.14000000")
    end

    test "quotes a direct-quote currency into USD at its bid parity" do
      assert rate(:FJD, :USD) == Decimal.new("0.44580000")
    end

    test "quotes USD into a direct-quote currency at the inverse of its ask parity" do
      assert rate(:USD, :FJD) == Decimal.new("2.188662727073757933902385642372510")
    end
  end

  describe "cross-currency rates" do
    test "divides the target's ask parity by the source's bid parity between two indirect quotes" do
      assert rate(:SCR, :VUV) == Decimal.new("8.734038413922393972622121608715644")
      assert rate(:VUV, :SCR) == Decimal.new("0.1301482433590402742073693230505570")
      assert rate(:SCR, :JPY) == Decimal.new("11.26100951505075872802518481836511")
      assert rate(:JPY, :SCR) == Decimal.new("0.09543986427045368857609651878848812")
    end

    test "divides the source's bid parity by the target's ask parity between two direct quotes" do
      assert rate(:FJD, :TOP) == Decimal.new("1.035540069686411149825783972125436")
      assert rate(:TOP, :FJD) == Decimal.new("0.8875027358284088421974173779820530")
      assert rate(:SBD, :WST) == Decimal.new("0.3164289487585842577918647649234020")
      assert rate(:GBP, :EUR) == Decimal.new("1.168923611111111111111111111111111")
      assert rate(:EUR, :GBP) == Decimal.new("0.8550853749072011878247958426132146")
    end

    test "inverts the product of both bid parities from an indirect to a direct quote" do
      assert rate(:SCR, :FJD) == Decimal.new("0.1586897079679324281450225251312526")
      assert rate(:JPY, :FJD) == Decimal.new("0.01409550312291509889433182043479214")
      assert rate(:THB, :EUR) == Decimal.new("0.02597864409974593925216212461248956")
    end

    test "multiplies both bid parities from a direct to an indirect quote" do
      assert rate(:FJD, :SCR) == Decimal.new("6.301605900000000000000000000000000")
      assert rate(:FJD, :JPY) == Decimal.new("70.94461200000000000000000000000000")
      assert rate(:EUR, :THB) == Decimal.new("38.49315600000000000000000000000000")
    end
  end

  describe "unquoted currencies" do
    test "returns an error when the source currency is absent from the bulletin" do
      assert {:error, %PTAX.CurrencyNotQuotedError{} = error} = Rates.rate(:ZWL, :USD, @date)
      assert Exception.message(error) == "PTAX does not quote :ZWL"
    end

    test "returns an error when the target currency is absent from the bulletin" do
      assert {:error, %PTAX.CurrencyNotQuotedError{} = error} = Rates.rate(:USD, :ZWL, @date)
      assert Exception.message(error) == "PTAX does not quote :ZWL"
    end
  end

  describe "unavailable quotes" do
    test "returns an error when no bulletin was published for the date" do
      assert {:error, %PTAX.QuotesNotFoundError{} = error} =
               Rates.rate(:USD, :BRL, ~D[2025-12-25])

      assert Exception.message(error) == "no quotes published for 2025-12-25"
    end
  end

  defp rate(from_currency, to_currency) do
    {:ok, rate} = Rates.rate(from_currency, to_currency, @date)
    rate
  end
end
