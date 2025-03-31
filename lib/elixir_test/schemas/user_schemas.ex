defmodule ElixirTest.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "User",
      description: "A user of the application",
      type: :object,
      properties: %{
        _id: %Schema{type: :string, description: "User ID", format: :uuid},
        email: %Schema{type: :string, description: "Email address", format: :email},
        created_at: %Schema{type: :string, description: "Creation timestamp", format: :"date-time"}
      },
      required: [:_id, :email],
      example: %{
        "_id" => "550e8400-e29b-41d4-a716-446655440000",
        "email" => "user@example.com",
        "created_at" => "2023-03-31T12:34:55Z"
      }
    })
  end

  defmodule UserRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "UserRequest",
      description: "Request schema for creating a user",
      type: :object,
      properties: %{
        email: %Schema{type: :string, description: "Email address", format: :email}
      },
      required: [:email],
      example: %{
        "email" => "user@example.com"
      }
    })
  end

  defmodule UserResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "UserResponse",
      description: "Response schema for user creation",
      type: :object,
      properties: %{
        user_id: %Schema{type: :string, description: "User ID", format: :uuid},
        email: %Schema{type: :string, description: "Email address", format: :email},
        generated_password: %Schema{type: :string, description: "Generated password"},
        message: %Schema{type: :string, description: "Success message"}
      },
      required: [:user_id, :email, :generated_password, :message],
      example: %{
        "user_id" => "550e8400-e29b-41d4-a716-446655440000",
        "email" => "user@example.com",
        "generated_password" => "abcdef123456",
        "message" => "Please store your password securely"
      }
    })
  end

  defmodule LoginRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "LoginRequest",
      description: "Request schema for user login",
      type: :object,
      properties: %{
        email: %Schema{type: :string, description: "Email address", format: :email},
        password: %Schema{type: :string, description: "User password"}
      },
      required: [:email, :password],
      example: %{
        "email" => "user@example.com",
        "password" => "password123"
      }
    })
  end

  defmodule LoginResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "LoginResponse",
      description: "Response schema for user login",
      type: :object,
      properties: %{
        token: %Schema{type: :string, description: "Authentication token"}
      },
      required: [:token],
      example: %{
        "token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    })
  end

  defmodule PasswordChangeRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PasswordChangeRequest",
      description: "Request schema for changing password",
      type: :object,
      properties: %{
        email: %Schema{type: :string, description: "Email address", format: :email},
        current_password: %Schema{type: :string, description: "Current password"},
        new_password: %Schema{type: :string, description: "New password"}
      },
      required: [:email, :current_password, :new_password],
      example: %{
        "email" => "user@example.com",
        "current_password" => "oldpassword",
        "new_password" => "newpassword"
      }
    })
  end

  defmodule MessageRequest do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "MessageRequest",
      description: "Request schema for sending a message",
      type: :object,
      properties: %{
        content: %Schema{type: :string, description: "Message content"},
        recipient_email: %Schema{type: :string, description: "Email of the message recipient", format: :email}
      },
      required: [:content, :recipient_email],
      example: %{
        "content" => "Hello, world!",
        "recipient_email" => "recipient@example.com"
      }
    })
  end

  defmodule Message do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Message",
      description: "A message in the system",
      type: :object,
      properties: %{
        content: %Schema{type: :string, description: "Message content"},
        created_at: %Schema{type: :string, description: "Creation timestamp", format: :"date-time"},
        sender_email: %Schema{type: :string, description: "Email of the message sender", format: :email}
      },
      required: [:content, :created_at],
      example: %{
        "content" => "Hello, world!",
        "created_at" => "2023-03-31T12:34:55Z",
        "sender_email" => "sender@example.com"
      }
    })
  end

  defmodule MessagesResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "MessagesResponse",
      description: "Response schema for retrieving messages",
      type: :array,
      items: Message,
      example: [
        %{
          "content" => "Hello, world!",
          "created_at" => "2023-03-31T12:34:55Z",
          "sender_email" => "sender@example.com"
        },
        %{
          "content" => "Another message",
          "created_at" => "2023-03-31T13:45:00Z",
          "sender_email" => "other.sender@example.com"
        }
      ]
    })
  end
end
