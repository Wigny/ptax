defmodule PTAX.QuotationTest do
  use ExUnit.Case

  alias PTAX.Quotation

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "quotation" do
    test "get/2 returns the struct with the data of the quotation" do
      assert {:ok, quotation} = Quotation.get(:USD, ~D[2021-12-24])

      assert %Quotation{
               buy: Decimal.from_float(5.6541),
               sell: Decimal.from_float(5.6591),
               quoted_in: DateTime.from_naive!(~N[2021-12-24 11:04:02.178], "America/Sao_Paulo"),
               bulletin: Quotation.Bulletin.Closing
             } == quotation
    end
  end
end
