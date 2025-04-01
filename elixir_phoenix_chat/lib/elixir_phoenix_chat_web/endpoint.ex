defmodule ElixirPhoenixChatWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :elixir_phoenix_chat

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_elixir_phoenix_chat_key",
    signing_salt: "GKFRjPVB",
    same_site: "Lax"
  ]

  # socket "/live", Phoenix.LiveView.Socket,
  #   websocket: [connect_info: [session: @session_options]],
  #   longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :elixir_phoenix_chat,
    gzip: false,
    only: ElixirPhoenixChatWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :elixir_phoenix_chat
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # CORS support using Corsica
  plug Corsica, origins: "*"

  # Add security headers
  plug :put_secure_browser_headers

  plug ElixirPhoenixChatWeb.Router

  # Function to add security headers to all responses
  def put_secure_browser_headers(conn, _opts) do
    Plug.Conn.merge_resp_headers(conn, [
      {"content-security-policy", "default-src 'self'"},
      {"x-content-type-options", "nosniff"},
      {"x-frame-options", "SAMEORIGIN"},
      {"x-xss-protection", "1; mode=block"},
      {"strict-transport-security", "max-age=31536000; includeSubDomains"}
    ])
  end
end
