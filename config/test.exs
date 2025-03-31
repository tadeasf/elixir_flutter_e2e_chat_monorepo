import Config

# Disable caching for OpenApiSpex in test environment
config :open_api_spex, :cache_adapter, OpenApiSpex.Plug.NoneCache
