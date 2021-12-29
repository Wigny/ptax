import Config

config :tesla, adapter: Tesla.Adapter.Hackney
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

import_config "#{config_env()}.exs"
