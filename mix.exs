defmodule JS2E.Mixfile do
  use Mix.Project

  def project do
    [app: :js2e,
     version: "2.0.0",
     elixir: "~> 1.5",
     deps: deps(),
     aliases: aliases(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,

     # Packaging
     escript: [
       main_module: JS2E,
       name: "js2e",
     ],

     # Dialyxir
     dialyzer: [plt_add_deps: :project],

     # Docs
     name: "JS2E",
     source_url: "https://github.com/dragonwasrobot/json-schema-to-elm/",

     # Test coverage
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test
     ]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:apex, "~>1.0"},
      {:excoveralls, "~> 0.7", only: :test},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:poison, "~> 3.0"}
    ]
  end

  defp aliases do
    [
      "build": ["deps.get", "compile", "escript.build"]
    ]
  end

end
