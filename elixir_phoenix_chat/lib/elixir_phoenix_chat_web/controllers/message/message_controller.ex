defmodule ElixirPhoenixChatWeb.MessageController do
  use ElixirPhoenixChatWeb, :controller
  use PhoenixSwagger

  alias ElixirPhoenixChat.Repo
  alias ElixirPhoenixChat.Schemas.Message
  alias ElixirPhoenixChat.Utils.JsonHelpers

  require Logger

  # Swagger documentation
  swagger_path :send_message do
    post "/api/messages"
    summary "Send a message"
    description "Sends a message to a specific user by email"
    security [%{JWT: []}]
    parameter :body, :body, Schema.ref(:MessageRequest), "Message parameters", required: true
    response 201, "Message sent"
    response 401, "Invalid token"
    response 404, "Recipient not found"
    response 500, "Server error"
  end

  def send_message(conn, %{"content" => content, "recipient_email" => recipient_email}) do
    user_id = conn.assigns.current_user_id

    with {:ok, recipient} <- find_user_by_email(recipient_email),
         {:ok, sender} <- Repo.find_one("users", %{"_id" => user_id}) do

      # Create message changeset for validation
      changeset = Message.changeset(%Message{}, %{
        user_id: user_id,
        recipient_id: recipient["_id"],
        content: content
      })

      if changeset.valid? do
        # Convert changeset to MongoDB document
        message = %{
          "user_id" => user_id,
          "recipient_id" => recipient["_id"],
          "content" => content,
          "created_at" => DateTime.utc_now()
        }

        # Start task to insert message
        Task.Supervisor.start_child(ElixirPhoenixChat.TaskSupervisor, fn ->
          case Repo.insert("messages", message) do
            {:ok, _} ->
              Logger.info("Message sent by user: #{user_id} to recipient: #{recipient["_id"]}")
            {:error, error} ->
              Logger.error("Failed to save message: #{inspect(error)}")
          end
        end)

        # Return success response
        conn
        |> put_status(:created)
        |> json(%{
          message: "user #{sender["email"]} sent message to #{recipient_email}"
        })
      else
        # Return validation errors
        conn
        |> put_status(:bad_request)
        |> json(%{errors: format_changeset_errors(changeset)})
      end
    else
      {:error, :not_found} ->
        Logger.warning("Recipient not found: #{recipient_email}")
        conn |> put_status(:not_found) |> json(%{error: "Recipient not found"})
      _ ->
        Logger.warning("Error processing message")
        conn |> put_status(:internal_server_error) |> json(%{error: "Error processing message"})
    end
  end

  def send_message(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Content and recipient_email are required"})
  end

  # Swagger documentation
  swagger_path :get_messages do
    get "/api/messages"
    summary "Get user messages"
    description "Retrieves all messages for the authenticated user"
    security [%{JWT: []}]
    response 200, "Success", Schema.array(:Message)
    response 401, "Invalid token"
    response 500, "Failed to retrieve messages"
    response 504, "Request timeout"
  end

  def get_messages(conn, _params) do
    user_id = conn.assigns.current_user_id
    Logger.info("Getting messages for user: #{user_id}")

    # Fetch messages with timeout handling
    task = Task.Supervisor.async(ElixirPhoenixChat.TaskSupervisor, fn ->
      # Use $or to find messages where user is either sender or recipient
      case Repo.find("messages", %{"$or" => [
        %{"recipient_id" => user_id},
        %{"user_id" => user_id}
      ]}) do
        {:ok, messages} ->
          Logger.info("Found #{length(messages)} raw messages for user: #{user_id}")
          # Fetch sender info and format messages
          formatted_messages = Enum.map(messages, fn message ->
            # Ensure message has string keys (helps with processing)
            message = for {k, v} <- message, into: %{}, do: {to_string(k), v}

            # Get sender info
            sender_result = Repo.find_one("users", %{"_id" => message["user_id"]})
            # Get recipient info
            recipient_result = Repo.find_one("users", %{"_id" => message["recipient_id"]})

            sender_email = case sender_result do
              {:ok, sender} -> sender["email"]
              _ -> "unknown"
            end

            recipient_email = case recipient_result do
              {:ok, recipient} -> recipient["email"]
              _ -> "unknown"
            end

            # Create message map with all ObjectIds converted to strings
            processed_message = %{
              "id" => message["_id"],
              "content" => message["content"],
              "created_at" => message["created_at"],
              "sender_email" => sender_email,
              "recipient_email" => recipient_email,
              "is_sent" => message["user_id"] == user_id
            }

            # Use JsonHelpers to convert any BSON.ObjectId to strings
            JsonHelpers.encode_mongo_document(processed_message)
          end)

          Logger.info("Retrieved #{length(formatted_messages)} messages for user: #{user_id}")
          {:ok, formatted_messages}

        {:error, error} ->
          Logger.error("Failed to retrieve messages: #{inspect(error)}")
          {:error, error}
      end
    end)

    # Wait for the task result with timeout
    try do
      Logger.info("Awaiting task result...")
      case Task.await(task, 15000) do
        {:ok, messages} ->
          Logger.info("Successfully got #{length(messages)} messages")
          conn |> json(messages)
        {:error, error} ->
          Logger.error("Error in task result: #{inspect(error)}")
          conn |> put_status(:internal_server_error) |> json(%{error: "Failed to retrieve messages"})
      end
    catch
      :exit, reason ->
        Logger.error("Task timed out or crashed: #{inspect(reason)}")
        conn |> put_status(:gateway_timeout) |> json(%{error: "Request timeout"})
    end
  end

  # Helper functions
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
      Message: swagger_schema do
        title "Message"
        description "A message in the system"
        properties do
          id :string, "Message ID", format: :uuid
          content :string, "Message content"
          created_at :string, "Creation timestamp", format: :"date-time"
          sender_email :string, "Email of the message sender", format: :email
        end
        required [:id, :content, :created_at]
      end,
      MessageRequest: swagger_schema do
        title "MessageRequest"
        description "Request schema for sending a message"
        properties do
          content :string, "Message content"
          recipient_email :string, "Email of the message recipient", format: :email
        end
        required [:content, :recipient_email]
      end
    }
  end
end
