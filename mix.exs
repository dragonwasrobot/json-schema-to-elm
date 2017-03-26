defmodule JS2.Mixfile do
  use Mix.Project

  def project do
    [app: :js2e,
     version: "1.0.0",
     elixir: "~> 1.4",
     deps: deps(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,

     # Packaging
     escript: [
       main_module: JS2E,
       name: "js2e"
     ],

     # Dialyxir
     dialyzer: [plt_add_deps: :project],

     # Docs
     name: "JS2E",
     source_url: "https://github.com/dragonwasrobot/json-schema-to-elm/"
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 3.0"},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:apex, "~>1.0.0"}
    ]
  end
end
