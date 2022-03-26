import Config

config :elixir, ansi_enabled: true

config :js2e, templates_location: "./priv/templates/"
config :js2e, output_location: "js2e_output"

import_config "#{Mix.env()}.exs"
