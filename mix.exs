defmodule PTAX.MixProject do
  use Mix.Project

  def project do
    [
      app: :ptax,
      version: "0.2.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.3"},
      {:typed_struct, "~> 0.2.1"},
      {:enum_type, "~> 1.1"},
      {:decimal, "~> 2.0"},
      {:casex, "~> 0.4.2"},
      {:timex, "~> 3.7"},
      {:ex_doc, "~> 0.26", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    "A currency converter that uses the API provided by the Brazilian Open Data Portal to perform quotes."
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/wigny/ptax"}
    ]
  end
end
