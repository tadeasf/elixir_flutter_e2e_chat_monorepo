defmodule ElixirTest.Controllers.UserController do
  import Plug.Conn
  use Plug.Builder
  use OpenApiSpex.ControllerSpecs

  alias ElixirTest.Auth
  alias ElixirTest.Database.DatabaseWorker
  alias ElixirTest.Schemas.{
    UserRequest, UserResponse,
    LoginRequest, LoginResponse,
    PasswordChangeRequest,
    MessageRequest, MessagesResponse
  }
  require Logger

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  tags ["users", "messages"]
  security [%{"bearerAuth" => []}]

  operation :create,
    summary: "Create a new user",
    description: "Creates a new user with the given email and generates a secure password",
    request_body: {"User creation parameters", "application/json", UserRequest},
    responses: [
      created: {"User created successfully", "application/json", UserResponse},
      bad_request: "Invalid request parameters",
      internal_server_error: "Server error"
    ]

  def create(conn) do
    user_id = UUID.uuid4()
    password = generate_password()
    hashed_password = Bcrypt.hash_pwd_salt(password)

    case conn.body_params do
      %{"email" => email} when is_binary(email) and email != "" ->
        # Check for existing email
        case check_existing_email(email) do
          {:ok, nil} ->
            user = %{
              _id: user_id,
              email: email,
              password_hash: hashed_password,
              created_at: DateTime.utc_now()
            }

            # Use Task.Supervisor instead of DynamicSupervisor
            _task = Task.Supervisor.async_nolink(ElixirTest.TaskSupervisor, fn ->
              case DatabaseWorker.insert("users", user) do
                {:ok, _result} ->
                  Logger.info("Created new user with ID: #{user_id}, email: #{email}")
                  :ok
                {:error, error} ->
                  Logger.error("Failed to create user: #{inspect(error)}")
                  {:error, error}
              end
            end)

            # Return success response without waiting for the task
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{
              user_id: user_id,
              email: email,
              generated_password: password,
              message: "Please store your password securely"
            }))

          {:ok, _existing_user} ->
            Logger.warning("Attempted to create user with existing email: #{email}")
            send_resp(conn, 400, "Email already exists")

          {:error, error} ->
            Logger.error("Database error checking email: #{inspect(error)}")
            send_resp(conn, 500, "Internal server error")
        end

      %{"email" => ""} ->
        Logger.warning("Attempted to create user with empty email")
        send_resp(conn, 400, "Email is required")

      _ ->
        Logger.warning("Invalid parameters for user creation: #{inspect(conn.body_params)}")
        send_resp(conn, 400, "Email is required")
    end
  end

  operation :login,
    summary: "User login",
    description: "Authenticates a user with email and password, returning a JWT token",
    request_body: {"Login parameters", "application/json", LoginRequest},
    responses: [
      ok: {"Login successful", "application/json", LoginResponse},
      unauthorized: "Invalid credentials"
    ],
    security: [%{}]

  def login(conn) do
    with {:ok, %{"email" => email, "password" => password}} <- parse_body(conn),
         {:ok, user} <- find_user_by_email(email),
         true <- Bcrypt.verify_pass(password, user["password_hash"]) do
      token = Auth.generate_token(user["_id"])

      # Log login without waiting
      Task.Supervisor.start_child(ElixirTest.TaskSupervisor, fn ->
        Logger.info("Successful login for user: #{user["_id"]} (#{email})")
      end)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{token: token}))
    else
      _ ->
        Logger.warning("Failed login attempt for email: #{conn.body_params["email"]}")
        send_resp(conn, 401, "Invalid credentials")
    end
  end

  operation :change_password,
    summary: "Change user password",
    description: "Changes user password after verifying the current password",
    request_body: {"Password change parameters", "application/json", PasswordChangeRequest},
    responses: [
      ok: "Password updated successfully",
      unauthorized: "Invalid credentials"
    ],
    security: [%{}]

  def change_password(conn) do
    with {:ok, %{"email" => email, "current_password" => current_password, "new_password" => new_password}} <- parse_body(conn),
         {:ok, user} <- find_user_by_email(email),
         true <- Bcrypt.verify_pass(current_password, user["password_hash"]) do
      new_password_hash = Bcrypt.hash_pwd_salt(new_password)

      # Use Task.Supervisor instead of DynamicSupervisor
      _task = Task.Supervisor.async_nolink(ElixirTest.TaskSupervisor, fn ->
        case DatabaseWorker.update("users",
          %{"_id" => user["_id"]},
          %{"$set" => %{"password_hash" => new_password_hash}}
        ) do
          {:ok, _} ->
            Logger.info("Password changed successfully for user: #{user["_id"]} (#{email})")
            :ok
          {:error, error} ->
            Logger.error("Failed to update password: #{inspect(error)}")
            {:error, error}
        end
      end)

      # We don't need to wait for the result
      send_resp(conn, 200, "Password updated successfully")
    else
      _ ->
        Logger.warning("Failed password change attempt for email: #{conn.body_params["email"]}")
        send_resp(conn, 401, "Invalid credentials")
    end
  end

  operation :send_message,
    summary: "Send a message",
    description: "Sends a message to a specific user by email",
    request_body: {"Message parameters", "application/json", MessageRequest},
    responses: [
      created: "Message sent",
      unauthorized: "Invalid token",
      not_found: "Recipient not found",
      internal_server_error: "Server error"
    ]

  def send_message(conn) do
    with {:ok, %{"content" => content, "recipient_email" => recipient_email}} <- parse_body(conn),
         {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Auth.verify_token(token),
         {:ok, recipient} <- find_user_by_email(recipient_email),
         {:ok, sender} <- DatabaseWorker.find_one("users", %{"_id" => claims["user_id"]}) do

      message = %{
        user_id: claims["user_id"],
        recipient_id: recipient["_id"],
        content: content,
        created_at: DateTime.utc_now()
      }

      # Use Task.Supervisor instead of DynamicSupervisor
      _task = Task.Supervisor.async_nolink(ElixirTest.TaskSupervisor, fn ->
        case DatabaseWorker.insert("messages", message) do
          {:ok, _} ->
            Logger.info("Message sent by user: #{claims["user_id"]} to recipient: #{recipient["_id"]}")
            :ok
          {:error, error} ->
            Logger.error("Failed to save message: #{inspect(error)}")
            {:error, error}
        end
      end)

      # Return JSON response with sender and recipient information
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, Jason.encode!(%{
        message: "user #{sender["email"]} sent message to #{recipient_email}"
      }))
    else
      {:error, :missing_token} ->
        Logger.warning("Missing authorization token for message send")
        send_resp(conn, 401, "Missing authorization token")
      {:error, :not_found} ->
        Logger.warning("Recipient not found")
        send_resp(conn, 404, "Recipient not found")
      _ ->
        Logger.warning("Invalid token or missing required parameters for message send")
        send_resp(conn, 401, "Invalid token or missing required parameters")
    end
  end

  operation :get_messages,
    summary: "Get user messages",
    description: "Retrieves all messages for the authenticated user",
    responses: [
      ok: {"List of messages", "application/json", MessagesResponse},
      unauthorized: "Invalid token",
      internal_server_error: "Failed to retrieve messages",
      gateway_timeout: "Request timeout"
    ]

  def get_messages(conn) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Auth.verify_token(token) do

      # Use Task.Supervisor instead of DynamicSupervisor for task management
      task = Task.Supervisor.async(ElixirTest.TaskSupervisor, fn ->
        case DatabaseWorker.find("messages", %{"recipient_id" => claims["user_id"]}) do
          {:ok, messages} ->
            formatted_messages = Enum.map(messages, fn message ->
              # Get sender info if needed
              sender_id = message["user_id"]
              case DatabaseWorker.find_one("users", %{"_id" => sender_id}) do
                {:ok, sender} ->
                  Map.merge(
                    Map.take(message, ["content", "created_at"]),
                    %{"sender_email" => sender["email"]}
                  )
                _ ->
                  Map.take(message, ["content", "created_at"])
              end
            end)
            Logger.info("Retrieved #{length(formatted_messages)} messages for user: #{claims["user_id"]}")
            {:ok, formatted_messages}
          {:error, error} ->
            Logger.error("Failed to retrieve messages: #{inspect(error)}")
            {:error, error}
        end
      end)

      # Wait for the result with timeout
      try do
        case Task.await(task, 5000) do
          {:ok, messages} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(messages))
          {:error, _} ->
            send_resp(conn, 500, "Failed to retrieve messages")
        end
      catch
        :exit, _ ->
          send_resp(conn, 504, "Request timeout")
      end
    else
      _ ->
        Logger.warning("Unauthorized message retrieval attempt")
        send_resp(conn, 401, "Invalid token")
    end
  end

  # New endpoint for fetching current user details
  operation :get_current_user,
    summary: "Get current user details",
    description: "Retrieves details for the authenticated user",
    responses: [
      ok: {"User details", "application/json", ElixirTest.Schemas.User},
      unauthorized: "Invalid token"
    ],
    security: [%{"bearerAuth" => []}]

  def get_current_user(conn) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Auth.verify_token(token),
         {:ok, user} <- DatabaseWorker.find_one("users", %{"_id" => claims["user_id"]}) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(user))
    else
      _ ->
        send_resp(conn, 401, "Invalid token")
    end
  end

  # Helper functions
  defp generate_password do
    :crypto.strong_rand_bytes(12)
    |> Base.encode64()
    |> binary_part(0, 12)
  end

  defp find_user_by_email(email) do
    case DatabaseWorker.find_one("users", %{"email" => email}) do
      {:ok, nil} ->
        Logger.warning("User not found with email: #{email}")
        {:error, :not_found}
      {:ok, user} -> {:ok, user}
      {:error, error} ->
        Logger.error("Error finding user: #{inspect(error)}")
        {:error, error}
    end
  end

  defp check_existing_email(email) do
    case DatabaseWorker.find_one("users", %{"email" => email}) do
      {:ok, nil} -> {:ok, nil}
      {:ok, user} -> {:ok, user}
      {:error, error} ->
        Logger.error("Error checking email existence: #{inspect(error)}")
        {:error, error}
    end
  end

  defp parse_body(conn) do
    case conn.body_params do
      %{} = params -> {:ok, params}
      _ -> {:error, :invalid_params}
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :missing_token}
    end
  end
end
