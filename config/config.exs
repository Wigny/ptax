import Config

tesla_adapter = if config_env() != :test, do: Tesla.Adapter.Hackney, else: Tesla.Mock

config :tesla, adapter: tesla_adapter
