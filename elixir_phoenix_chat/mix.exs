defmodule ElixirPhoenixChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_phoenix_chat,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ElixirPhoenixChat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto, "~> 3.10"},
      {:mongodb_driver, "~> 1.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:phoenix_swagger, "~> 0.8.3"},
      {:ex_json_schema, "~> 0.7.1"},
      {:bcrypt_elixir, "~> 3.0"},
      {:uuid, "~> 1.1"},
      {:joken, "~> 2.6"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      # Security-related dependencies
      {:cloak, "~> 1.1.2"},            # For field encryption
      {:cloak_ecto, "~> 1.2.0"},       # Ecto integration for Cloak
      {:html_sanitize_ex, "~> 1.4.2"}, # For XSS prevention on content
      {:corsica, "~> 1.3"}             # For proper CORS headers
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind elixir_phoenix_chat", "esbuild elixir_phoenix_chat"],
      "assets.deploy": [
        "tailwind elixir_phoenix_chat --minify",
        "esbuild elixir_phoenix_chat --minify",
        "phx.digest"
      ],
      "security.encrypt": ["encrypt_messages"] # Add custom mix task for encryption migration
    ]
  end
end
