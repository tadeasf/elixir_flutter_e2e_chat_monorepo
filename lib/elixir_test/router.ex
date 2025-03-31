defmodule ElixirTest.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug Plug.Logger
  plug :match

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
