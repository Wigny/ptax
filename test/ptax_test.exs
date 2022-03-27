defmodule PTAXTest do
  use ExUnit.Case
  doctest PTAX

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end
end
