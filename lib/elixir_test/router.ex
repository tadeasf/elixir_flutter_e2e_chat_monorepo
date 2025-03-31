defmodule ElixirTest.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug Plug.Logger
  plug :match

  # Add CORS plug to handle preflight requests and set CORS headers
  plug CORSPlug, origin: "*"

  # Add the PutApiSpec plug to make the API spec available
  plug OpenApiSpex.Plug.PutApiSpec, module: ElixirTest.ApiSpec

  # Configure request parsing with timeout and length limits
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    length: 8_000_000  # 8MB limit

  plug :dispatch

  alias ElixirTest.Controllers.UserController

  # Define a body reader that handles streaming request bodies
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    {:ok, body, conn}
  end

  # Serve OpenAPI spec
  get "/api/openapi" do
    OpenApiSpex.Plug.RenderSpec.call(conn, [])
  end

  # Serve Swagger UI
  get "/swaggerui" do
    html = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>ElixirTest API</title>
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui.css">
      </head>
      <body>
        <div id="swagger-ui"></div>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui-bundle.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui-standalone-preset.js"></script>
        <script>
          window.onload = function() {
            window.ui = SwaggerUIBundle({
              url: "/api/openapi",
              dom_id: '#swagger-ui',
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIStandalonePreset
              ],
              layout: "StandaloneLayout",
              deepLinking: true
            });
          }
        </script>
      </body>
    </html>
    """

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  post "/users" do
    UserController.create(conn)
  end

  post "/users/login" do
    UserController.login(conn)
  end

  put "/users/change-password" do
    UserController.change_password(conn)
  end

  post "/messages" do
    UserController.send_message(conn)
  end

  get "/messages/:user_id" do
    UserController.get_messages(conn)
  end

  # Handle OPTIONS requests for CORS preflight
  options _ do
    conn
    |> Plug.Conn.put_resp_header("allow", "GET, POST, PUT, OPTIONS")
    |> Plug.Conn.send_resp(204, "")
  end

  match _ do
    Logger.warning("Route not found: #{conn.request_path}")
    send_resp(conn, 404, "Not found")
  end

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    Logger.error("""
    Error occurred:
    Kind: #{inspect(kind)}
    Reason: #{inspect(reason)}
    Stack trace:
    #{Exception.format_stacktrace(stack)}
    """)
    send_resp(conn, conn.status || 500, "Something went wrong")
  end
end
