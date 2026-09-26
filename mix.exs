defmodule PTAX.MixProject do
  use Mix.Project

  @version "3.0.0"
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
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:ex_money, "~> 6.2"},
      {:decimal, "~> 3.1"},
      {:req, "~> 0.7"},
      {:tzdata, "~> 1.2"},
      {:dayoff, "~> 0.2"},
      {:plug, "~> 1.20", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
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
