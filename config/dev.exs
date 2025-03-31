import Config

# Disable caching for OpenApiSpex in development
config :open_api_spex, :cache_adapter, OpenApiSpex.Plug.NoneCache
