defmodule ElmGenerator.Mixfile do
  use Mix.Project

  def project do
    [app: :decoder,
     version: "1.0.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 3.0"},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
     {:apex, "~>1.0.0"}
    ]
  end
end
