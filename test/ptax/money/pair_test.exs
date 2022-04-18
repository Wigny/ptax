defmodule PTAX.Money.PairTest do
  use ExUnit.Case
  doctest PTAX.Money.Pair

  defmodule TeslaMiddlewareXML do
    @behaviour Tesla.Middleware

    @impl Tesla.Middleware
    def call(env, next, _options) do
      env
      |> Tesla.run(next)
      |> parse()
    end

    defp parse({:ok, env}) do
      body = XmlToMap.naive_map(env.body)
      {:ok, %{env | body: body}}
    end

    defp parse(res) do
      res
    end
  end

  describe "combine/2" do
    setup do
      client = Tesla.client([TeslaKeys.Middleware.Case, TeslaMiddlewareXML])

      %{body: moeda} = Tesla.get!(client, "https://www3.bcb.gov.br/bc_moeda/rest/moeda/data")

      {:ok, currencies} = PTAX.currencies()

      currencies =
        currencies
        # |> Enum.reject(&(&1 == :BRL))
        |> Enum.map(fn c ->
          %{"codigo" => codigo} =
            moeda |> get_in(~w[moedas moeda]) |> Enum.find(&(&1["codigo_swift"] == to_string(c)))

          {c, String.to_integer(codigo)}
        end)

      %{currencies: currencies, client: client}
    end

    test "combines two currency pairs based on the USD currency", %{
      currencies: currencies,
      client: client
    } do
      date = ~D[2022-04-14]

      for {currency1, code1} <- currencies, {currency2, code2} <- currencies do
        {:ok, %{pair: pair1}} = PTAX.Quotation.get(currency1, date)
        {:ok, %{pair: pair2}} = PTAX.Quotation.get(currency2, date)
        pair = PTAX.Money.Pair.combine(pair1, pair2)

        %{body: %{"valor_convertido" => valor_convertido}} =
          Tesla.get!(
            client,
            "https://www3.bcb.gov.br/bc_moeda/rest/converter/1/1/#{code1}/#{code2}/#{date}"
          )

        money1 = PTAX.Money.new(1, currency1)
        exchange = PTAX.Money.exchange(money1, pair)
        money2 = PTAX.Money.new(valor_convertido, currency2)

        assert exchange == money2,
               "#{inspect(money1)} should be #{inspect(money2)}, but it's #{inspect(exchange)}; #{pair.amount.bid}/#{pair.amount.ask} == #{valor_convertido}"
      end
    end
  end
end
