import Config

tesla_adapter =
  if config_env() != :test,
    do: {Tesla.Adapter.Hackney, ssl_options: [verify: :verify_none]},
    else: Tesla.Mock

config :tesla, adapter: tesla_adapter
