defmodule PTAX.MoedaTest do
  use ExUnit.Case

  alias PTAX.Moeda

  setup do
    PTAX.RequestsFixtures.fixture()

    :ok
  end

  describe "moeda" do
    test "get/2 retorna o struct com os dados da moeda" do
      assert {:ok, moedas} = Moeda.list()

      assert [
               %Moeda{nome: "Libra Esterlina", simbolo: :GBP},
               %Moeda{nome: "Dólar dos Estados Unidos", simbolo: :USD}
             ] == moedas
    end
  end
end
