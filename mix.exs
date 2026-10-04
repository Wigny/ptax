defmodule PTAX.MixProject do
  use Mix.Project

  @version "3.1.0"
  @source_url "https://github.com/wigny/ptax"

  def project do
    [
      app: :ptax,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: @source_url,
      description: description(),
      package: package(),
      docs: docs(),
      escript: escript(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:localize, github: "elixir-localize/localize", ref: "e2db004", override: true},
      {:ex_money, "~> 6.2"},
      {:decimal, "~> 3.1"},
      {:req, "~> 0.7"},
      {:tz, "~> 0.28"},
      {:spreadsheet, "~> 0.6", only: :test},
      {:plug, "~> 1.20", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp escript do
    [main_module: PTAX.CLI, include_priv_for: [:localize]]
  end

  defp description do
    "A currency converter backed by the Brazilian Central Bank (BCB) PTAX closing rates."
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: @version,
      extras: ["README.md"]
    ]
  end
end
