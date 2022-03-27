defmodule PTAX.QuotationTest do
  use ExUnit.Case
  doctest PTAX.Quotation

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end
end
