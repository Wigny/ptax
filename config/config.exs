import Config

config :localize,
  supported_locales: ["pt-BR", "en"]

config :ex_money, api_module: PTAX.ExchangeRates

if config_env() == :test do
  config :ptax, retriever: PTAX.ExchangeRates.RetrieverMock
end
