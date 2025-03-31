defmodule ElixirTest.Controllers.UserController do
  import Plug.Conn
  alias ElixirTest.Auth
  alias ElixirTest.Database.DatabaseWorker
  require Logger

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

  def send_message(conn) do
    with {:ok, %{"content" => content}} <- parse_body(conn),
         {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Auth.verify_token(token) do
      message = %{
        user_id: claims["user_id"],
        content: content,
        created_at: DateTime.utc_now()
      }

      # Use Task.Supervisor instead of DynamicSupervisor
      _task = Task.Supervisor.async_nolink(ElixirTest.TaskSupervisor, fn ->
        case DatabaseWorker.insert("messages", message) do
          {:ok, _} ->
            Logger.info("Message sent by user: #{claims["user_id"]}")
            :ok
          {:error, error} ->
            Logger.error("Failed to save message: #{inspect(error)}")
            {:error, error}
        end
      end)

      # We don't need to wait for the task to complete
      send_resp(conn, 201, "Message sent")
    else
      {:error, :missing_token} ->
        Logger.warning("Missing authorization token for message send")
        send_resp(conn, 401, "Missing authorization token")
      _ ->
        Logger.warning("Invalid token for message send")
        send_resp(conn, 401, "Invalid token")
    end
  end

  def get_messages(conn) do
    with {:ok, token} <- extract_token(conn),
         {:ok, claims} <- Auth.verify_token(token) do

      # Use Task.Supervisor instead of DynamicSupervisor for task management
      task = Task.Supervisor.async(ElixirTest.TaskSupervisor, fn ->
        case DatabaseWorker.find("messages", %{"user_id" => claims["user_id"]}) do
          {:ok, messages} ->
            messages = Enum.map(messages, &Map.take(&1, ["content", "created_at"]))
            Logger.info("Retrieved #{length(messages)} messages for user: #{claims["user_id"]}")
            {:ok, messages}
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
