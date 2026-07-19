import Config

config :ex_money, auto_start_exchange_rate_service: false

if config_env() == :test do
  config :ptax, http_client: PTAX.ExchangeRates.HTTPClientMock
end
