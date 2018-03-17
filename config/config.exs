use Mix.Config

config :elixir, ansi_enabled: true

config :js2e, templates_location: "./priv/templates/"

import_config "#{Mix.env()}.exs"
