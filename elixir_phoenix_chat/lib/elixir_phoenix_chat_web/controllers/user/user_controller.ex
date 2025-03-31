defmodule ElixirPhoenixChatWeb.UserController do
  use ElixirPhoenixChatWeb, :controller
  use PhoenixSwagger

  alias ElixirPhoenixChat.Repo
  alias ElixirPhoenixChat.Auth
  alias ElixirPhoenixChat.Schemas.User

  require Logger

  # Swagger documentation
  swagger_path :create do
    post "/api/users"
    summary "Create a new user"
    description "Creates a new user with the given email and generates a secure password"
    parameter :body, :body, Schema.ref(:UserRequest), "User creation parameters", required: true
    response 201, "User created successfully", Schema.ref(:UserResponse)
    response 400, "Invalid request parameters"
    response 500, "Server error"
  end

  def create(conn, %{"email" => email} = _params) when is_binary(email) and email != "" do
    # Generate user ID and password
    user_id = UUID.uuid4()
    password = generate_password()

    # Check for existing email
    case Repo.find_one("users", %{"email" => email}) do
      {:ok, nil} ->
        # Create user changeset for validation
        changeset = User.changeset(%User{}, %{
          id: user_id,
          email: email,
          password: password
        })

        if changeset.valid? do
          # We can use Ecto's changeset but insert directly with MongoDB
          user_data = Map.merge(
            %{
              "_id" => user_id,
              "email" => email,
              "password_hash" => Bcrypt.hash_pwd_salt(password),
              "created_at" => DateTime.utc_now()
            },
            Map.new(changeset.changes, fn {k, v} -> {Atom.to_string(k), v} end)
          )

          # Start task to insert user
          Task.Supervisor.start_child(ElixirPhoenixChat.TaskSupervisor, fn ->
            case Repo.insert("users", user_data) do
              {:ok, _result} ->
                Logger.info("Created new user with ID: #{user_id}, email: #{email}")
              {:error, error} ->
                Logger.error("Failed to create user: #{inspect(error)}")
            end
          end)

          # Return success response
          conn
          |> put_status(:created)
          |> json(%{
            user_id: user_id,
            email: email,
            generated_password: password,
            message: "Please store your password securely"
          })
        else
          # Return validation errors
          conn
          |> put_status(:bad_request)
          |> json(%{errors: format_changeset_errors(changeset)})
        end

      {:ok, _existing_user} ->
        Logger.warning("Attempted to create user with existing email: #{email}")
        conn |> put_status(:bad_request) |> json(%{error: "Email already exists"})

      {:error, error} ->
        Logger.error("Database error checking email: #{inspect(error)}")
        conn |> put_status(:internal_server_error) |> json(%{error: "Internal server error"})
    end
  end

  def create(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Email is required"})
  end

  # Swagger documentation
  swagger_path :login do
    post "/api/users/login"
    summary "User login"
    description "Authenticates a user with email and password, returning a JWT token"
    parameter :body, :body, Schema.ref(:LoginRequest), "Login parameters", required: true
    response 200, "Login successful", Schema.ref(:LoginResponse)
    response 401, "Invalid credentials"
  end

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- find_user_by_email(email),
         true <- Bcrypt.verify_pass(password, user["password_hash"]) do
      token = Auth.generate_token(user["_id"])

      # Log login without waiting
      Task.Supervisor.start_child(ElixirPhoenixChat.TaskSupervisor, fn ->
        Logger.info("Successful login for user: #{user["_id"]} (#{email})")
      end)

      conn |> json(%{token: token})
    else
      _ ->
        Logger.warning("Failed login attempt for email: #{email}")
        conn |> put_status(:unauthorized) |> json(%{error: "Invalid credentials"})
    end
  end

  def login(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Email and password are required"})
  end

  # Swagger documentation
  swagger_path :change_password do
    put "/api/users/change-password"
    summary "Change user password"
    description "Changes user password after verifying the current password"
    parameter :body, :body, Schema.ref(:PasswordChangeRequest), "Password change parameters", required: true
    response 200, "Password updated successfully"
    response 401, "Invalid credentials"
  end

  def change_password(conn, %{"email" => email, "current_password" => current_password, "new_password" => new_password}) do
    with {:ok, user} <- find_user_by_email(email),
         true <- Bcrypt.verify_pass(current_password, user["password_hash"]) do
      new_password_hash = Bcrypt.hash_pwd_salt(new_password)

      # Use Task.Supervisor for the update
      Task.Supervisor.start_child(ElixirPhoenixChat.TaskSupervisor, fn ->
        case Repo.update("users",
          %{"_id" => user["_id"]},
          %{"$set" => %{"password_hash" => new_password_hash}}
        ) do
          {:ok, _} ->
            Logger.info("Password changed successfully for user: #{user["_id"]} (#{email})")
          {:error, error} ->
            Logger.error("Failed to update password: #{inspect(error)}")
        end
      end)

      conn |> json(%{message: "Password updated successfully"})
    else
      _ ->
        Logger.warning("Failed password change attempt for email: #{email}")
        conn |> put_status(:unauthorized) |> json(%{error: "Invalid credentials"})
    end
  end

  def change_password(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Email, current_password and new_password are required"})
  end

  # Swagger documentation
  swagger_path :get_current_user do
    get "/api/users/me"
    summary "Get current user details"
    description "Retrieves details for the authenticated user"
    security [%{JWT: []}]
    response 200, "Success", Schema.ref(:User)
    response 401, "Invalid token"
  end

  def get_current_user(conn, _params) do
    # Use the current_user_id set by the Authentication plug
    case Repo.find_one("users", %{"_id" => conn.assigns.current_user_id}) do
      {:ok, user} when not is_nil(user) ->
        # Filter out sensitive information
        user_data = Map.drop(user, ["password_hash", "__v"])
        conn |> json(user_data)
      _ ->
        conn |> put_status(:not_found) |> json(%{error: "User not found"})
    end
  end

  # Helper functions
  defp generate_password do
    :crypto.strong_rand_bytes(12)
    |> Base.encode64()
    |> binary_part(0, 12)
  end

  defp find_user_by_email(email) do
    case Repo.find_one("users", %{"email" => email}) do
      {:ok, nil} ->
        Logger.warning("User not found with email: #{email}")
        {:error, :not_found}
      {:ok, user} -> {:ok, user}
      {:error, error} ->
        Logger.error("Error finding user: #{inspect(error)}")
        {:error, error}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  # Swagger schemas
  def swagger_definitions do
    %{
      User: swagger_schema do
        title "User"
        description "A user of the application"
        properties do
          id :string, "User ID", format: :uuid
          email :string, "Email address", format: :email
          created_at :string, "Creation timestamp", format: :"date-time"
        end
        required [:id, :email]
        example %{
          "id" => "550e8400-e29b-41d4-a716-446655440000",
          "email" => "user@example.com",
          "created_at" => "2023-03-31T12:34:55Z"
        }
      end,
      UserRequest: swagger_schema do
        title "UserRequest"
        description "Request schema for creating a user"
        properties do
          email :string, "Email address", format: :email
        end
        required [:email]
      end,
      UserResponse: swagger_schema do
        title "UserResponse"
        description "Response schema for user creation"
        properties do
          user_id :string, "User ID", format: :uuid
          email :string, "Email address", format: :email
          generated_password :string, "Generated password"
          message :string, "Success message"
        end
        required [:user_id, :email, :generated_password, :message]
      end,
      LoginRequest: swagger_schema do
        title "LoginRequest"
        description "Request schema for user login"
        properties do
          email :string, "Email address", format: :email
          password :string, "User password"
        end
        required [:email, :password]
      end,
      LoginResponse: swagger_schema do
        title "LoginResponse"
        description "Response schema for user login"
        properties do
          token :string, "Authentication token"
        end
        required [:token]
      end,
      PasswordChangeRequest: swagger_schema do
        title "PasswordChangeRequest"
        description "Request schema for changing password"
        properties do
          email :string, "Email address", format: :email
          current_password :string, "Current password"
          new_password :string, "New password"
        end
        required [:email, :current_password, :new_password]
      end
    }
  end
end
