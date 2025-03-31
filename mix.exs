defmodule ElixirTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_test,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirTest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mongodb_driver, "~> 1.3"},
      {:jason, "~> 1.4"},
      {:joken, "~> 2.6"},
      {:plug_cowboy, "~> 2.6"},
      {:bcrypt_elixir, "~> 3.0"},
      {:uuid, "~> 1.1"},
      {:libcluster, "~> 3.3"},
      {:open_api_spex, "~> 3.21"},
      {:cors_plug, "~> 3.0"}
    ]
  end
end
