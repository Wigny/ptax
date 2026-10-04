import Config

config :ex_money, auto_start_exchange_rate_service: false

config :localize, default_locale: "pt", allow_runtime_locale_download: true

if config_env() == :test do
  config :ptax, req_options: [plug: {Req.Test, PTAX.Quotes}, cache_dir: nil, retry: false]
end
