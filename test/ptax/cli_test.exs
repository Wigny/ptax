defmodule PTAX.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias PTAX.CLI

  setup do
    Req.Test.stub(PTAX.Quotes, PTAX.Quotes.Stub)
  end

  describe "conversion" do
    test "prints the amount converted at the rate published for the date" do
      assert capture_io(fn -> CLI.main(["100", "USD", "--date", "2026-07-31"]) end) ==
               "R$ 507,67\n"
    end

    test "prints the amount converted at the latest published rate" do
      assert capture_io(fn -> CLI.main(["100", "USD"]) end) == "R$ 507,67\n"
    end

    test "parses the amount and the currency from a single string" do
      assert capture_io(fn -> CLI.main(["US$ 5", "--date", "2026-07-31"]) end) ==
               "R$ 25,38\n"
    end

    test "converts to the currency given by --to" do
      assert capture_io(fn ->
               CLI.main(["100", "BRL", "--to", "USD", "--date", "2026-07-31"])
             end) == "US$ 19,70\n"
    end

    test "accepts the short aliases" do
      assert capture_io(fn -> CLI.main(["50", "GBP", "-t", "BRL", "-d", "2026-07-31"]) end) ==
               "R$ 341,82\n"
    end
  end

  describe "flags" do
    test "prints the version" do
      assert capture_io(fn -> CLI.main(["--version"]) end) ==
               "ptax #{Mix.Project.config()[:version]}\n"
    end

    test "prints the usage" do
      assert capture_io(fn -> CLI.main(["--help"]) end) =~ "Usage: ptax <money>"
    end
  end

  describe "errors" do
    test "fails when the amount is not a number" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["abc", "USD"])) == {:shutdown, 1}
             end) == "ptax: The currency \"abc USD\" is unknown or not supported\n"
    end

    test "fails when the source currency is not known" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "XYZ"])) == {:shutdown, 1}
             end) == "ptax: The currency \"XYZ\" is unknown or not supported\n"
    end

    test "fails when the target currency is not known" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "USD", "--to", "XYZ"])) == {:shutdown, 1}
             end) == "ptax: The currency \"XYZ\" is not known.\n"
    end

    test "fails when the target currency is absent from the bulletin" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "USD", "--to", "ZWL", "--date", "2026-07-31"])) ==
                        {:shutdown, 1}
             end) == "ptax: PTAX does not quote :ZWL\n"
    end

    test "fails when no bulletin was published for the date" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "USD", "--date", "2025-12-25"])) ==
                        {:shutdown, 1}
             end) == "ptax: no quotes published for 2025-12-25\n"
    end

    test "fails when the date is not ISO 8601" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "USD", "--date", "31/07/2026"])) ==
                        {:shutdown, 1}
             end) == "ptax: invalid date: 31/07/2026\n"
    end

    test "prints the usage and fails with status 64 when an option is not known" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main(["100", "USD", "--rate"])) == {:shutdown, 64}
             end) =~ "Usage: ptax <money>"
    end

    test "prints the usage and fails with status 64 when the money is missing" do
      assert capture_io(:stderr, fn ->
               assert catch_exit(CLI.main([])) == {:shutdown, 64}
             end) =~ "Usage: ptax <money>"
    end
  end
end
