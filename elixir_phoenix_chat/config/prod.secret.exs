use Mix.Config

secret_key_base = System.get_env("SECRET_KEY_BASE") ||
  raise """
  Environment variable SECRET_KEY_BASE is missing.
  """

encryption_key = System.get_env("ENCRYPTION_KEY") ||
  raise """
  Environment variable ENCRYPTION_KEY is missing.
  """

config :elixir_phoenix_chat,
  secret_key_base: secret_key_base,
  encryption_key: encryption_key
