# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_phoenix_chat,
  ecto_repos: [ElixirPhoenixChat.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :elixir_phoenix_chat, ElixirPhoenixChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ElixirPhoenixChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ElixirPhoenixChat.PubSub,
  live_view: [signing_salt: "dDAZyhm9"]

# Phoenix Swagger configuration
config :phoenix_swagger, json_library: Jason

config :elixir_phoenix_chat, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: ElixirPhoenixChatWeb.Router,
      endpoint: ElixirPhoenixChatWeb.Endpoint
    ]
  }

# JWT Secret Key for Auth - fallback to a default in dev, but expect env var in prod
config :joken, default_signer: [
  signer_alg: "HS256",
  key_octet: System.get_env("JWT_SECRET") || "some_very_secure_secret_key_that_should_be_in_env_vars"
]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  elixir_phoenix_chat: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  elixir_phoenix_chat: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
