import Config

if config_env() == :test, do: config(:tesla, adapter: Tesla.Mock)

config :ptax, PTAX.Gettext, default_locale: "pt_BR"
