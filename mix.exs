defmodule JS2E.MixProject do
  use Mix.Project

  @version "2.8.1"
  @elixir_version "~> 1.12"

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
    [extra_applications: [:logger, :eex]]
  end

  defp aliases do
    [
      build: ["deps.get", "compile", "escript.build"],
      check: ["credo --strict --ignore=RedundantBlankLines"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.28.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.4", only: :test, runtime: false},
      {:gradient, github: "esl/gradient", only: [:dev], runtime: false},
      # for local testing: {:json_schema, path: "../json_schema/"},
      {:json_schema, "~> 0.4.0"},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp description do
    """
    Generates Elm types, JSON decoders, JSON encoders and fuzz tests from JSON
    schema specifications.
    """
  end

  defp dialyzer do
    [plt_add_deps: :apps_direct]
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
