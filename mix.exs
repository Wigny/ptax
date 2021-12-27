defmodule PTAX.MixProject do
  use Mix.Project

  def project do
    [
      app: :ptax,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.3"},
      {:typed_struct, "~> 0.2.1"},
      {:enum_type, "~> 1.1"},
      {:tzdata, "~> 1.1"},
      {:decimal, "~> 2.0"}
    ]
  end
end
