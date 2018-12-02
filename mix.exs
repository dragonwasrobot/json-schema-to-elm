defmodule JS2E.Mixfile do
  use Mix.Project

  @version "2.7.0"
  @elixir_version "~> 1.7"

  def project do
    [
      app: :js2e,
      version: @version,
      elixir: @elixir_version,
      aliases: aliases(),
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      escript: escript(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: test_coverage(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp aliases do
    [
      build: ["deps.get", "compile", "escript.build"],
      check: ["credo --strict --ignore=RedundantBlankLines"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19-rc", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      # {:json_schema, path: "../json_schema/"},
      {:json_schema, "~> 0.1.0"}
    ]
  end

  defp description do
    """
    Generates Elm types, JSON decoders, JSON encoders and fuzz tests from JSON
    schema specifications.
    """
  end

  defp dialyzer do
    [plt_add_deps: :project]
  end

  defp docs do
    [
      name: "JSON Schema to Elm",
      formatter_opts: [gfm: true],
      source_ref: @version,
      source_url: "https://github.com/dragonwasrobot/json-schema-to-elm",
      extras: []
    ]
  end

  defp escript do
    [main_module: JS2E, name: "js2e"]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp test_coverage do
    [tool: ExCoveralls]
  end
end
