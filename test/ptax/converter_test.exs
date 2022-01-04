defmodule PTAX.ConverterTest do
  use ExUnit.Case
  alias PTAX.Converter

  @valid_opts %{
    from: :USD,
    to: :GBP,
    date: ~D[2021-12-24],
    operation: :sell,
    bulletin: PTAX.Quotation.Bulletin.Closing
  }

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "converter" do
    test "run/2 convert from one currency to another" do
      assert {:ok, Decimal.from_float(11.5247)} == Converter.run("15.45", @valid_opts)
    end

    test "run/2 throws error if unsupported options" do
      assert_raise FunctionClauseError, fn ->
        Converter.run("15.45", %{@valid_opts | operation: :vender})
      end

      assert_raise FunctionClauseError, fn ->
        Converter.run("15.45", %{@valid_opts | from: "USD"})
      end

      assert_raise FunctionClauseError, fn ->
        Converter.run("15.45", %{@valid_opts | to: 5})
      end
    end
  end
end
