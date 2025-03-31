defmodule ElixirPhoenixChatWeb.Router do
  use ElixirPhoenixChatWeb, :router
  use PhoenixSwagger

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Add authentication for routes that require it
  pipeline :auth do
    plug :accepts, ["json"]
    plug ElixirPhoenixChatWeb.Plugs.Authentication
  end

  # Swagger documentation route
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :elixir_phoenix_chat,
      swagger_file: "swagger.json"
  end

  # Public API routes (no auth required)
  scope "/api", ElixirPhoenixChatWeb do
    pipe_through :api

    # User routes
    post "/users", UserController, :create
    post "/users/login", UserController, :login
    put "/users/change-password", UserController, :change_password
  end

  # Protected API routes (auth required)
  scope "/api", ElixirPhoenixChatWeb do
    pipe_through [:api, :auth]

    # User routes
    get "/users/me", UserController, :get_current_user

    # Message routes
    post "/messages", MessageController, :send_message
    get "/messages", MessageController, :get_messages
  end

  # Swagger documentation info
  def swagger_info do
    ElixirPhoenixChatWeb.SwaggerInfo.swagger_info()
  end

  # Note: The swagger_spec and swagger_paths functions are now handled by
  # our custom implementation in Mix.Tasks.PhoenixSwagger.Generate
end
