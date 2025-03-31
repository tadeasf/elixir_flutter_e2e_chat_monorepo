defmodule ElixirTest.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, Server, Operation, Parameter, RequestBody, Response, Schema, MediaType}
  alias ElixirTest.Schemas.{
    UserRequest, UserResponse,
    LoginRequest, LoginResponse,
    PasswordChangeRequest,
    MessageRequest, MessagesResponse
  }
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Define server URL
        %Server{url: "http://localhost:4000", description: "Development server"}
      ],
      info: %Info{
        title: "ElixirTest API",
        version: "1.0.0",
        description: """
        API for ElixirTest application.
        Provides endpoints for user management and messaging.
        """
      },
      # Define paths manually instead of using from_router
      paths: %{
        "/users" => %{
          post: operation(:create_user)
        },
        "/users/login" => %{
          post: operation(:login)
        },
        "/users/change-password" => %{
          put: operation(:change_password)
        },
        "/messages" => %{
          post: operation(:send_message)
        },
        "/messages/{user_id}" => %{
          get: operation(:get_messages)
        }
      },
      components: %Components{
        securitySchemes: %{
          "bearerAuth" => %OpenApiSpex.SecurityScheme{
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
            description: "JWT Authorization header using the Bearer scheme"
          }
        }
      }
    }
  end

  # Define operations as separate functions for clarity
  defp operation(:create_user) do
    %Operation{
      tags: ["users"],
      summary: "Create a new user",
      description: "Creates a new user with the given email and generates a secure password",
      operationId: "ElixirTest.Controllers.UserController.create",
      requestBody: %RequestBody{
        description: "User creation parameters",
        content: %{
          "application/json" => %MediaType{
            schema: UserRequest.schema()
          }
        },
        required: true
      },
      responses: %{
        201 => %Response{
          description: "User created successfully",
          content: %{
            "application/json" => %MediaType{
              schema: UserResponse.schema()
            }
          }
        },
        400 => %Response{description: "Invalid request parameters"},
        500 => %Response{description: "Server error"}
      }
    }
  end

  defp operation(:login) do
    %Operation{
      tags: ["users"],
      summary: "User login",
      description: "Authenticates a user with email and password, returning a JWT token",
      operationId: "ElixirTest.Controllers.UserController.login",
      requestBody: %RequestBody{
        description: "Login parameters",
        content: %{
          "application/json" => %MediaType{
            schema: LoginRequest.schema()
          }
        },
        required: true
      },
      responses: %{
        200 => %Response{
          description: "Login successful",
          content: %{
            "application/json" => %MediaType{
              schema: LoginResponse.schema()
            }
          }
        },
        401 => %Response{description: "Invalid credentials"}
      }
    }
  end

  defp operation(:change_password) do
    %Operation{
      tags: ["users"],
      summary: "Change user password",
      description: "Changes user password after verifying the current password",
      operationId: "ElixirTest.Controllers.UserController.change_password",
      requestBody: %RequestBody{
        description: "Password change parameters",
        content: %{
          "application/json" => %MediaType{
            schema: PasswordChangeRequest.schema()
          }
        },
        required: true
      },
      responses: %{
        200 => %Response{description: "Password updated successfully"},
        401 => %Response{description: "Invalid credentials"}
      }
    }
  end

  defp operation(:send_message) do
    %Operation{
      tags: ["messages"],
      summary: "Send a message",
      description: "Sends a message on behalf of the authenticated user",
      operationId: "ElixirTest.Controllers.UserController.send_message",
      security: [%{"bearerAuth" => []}],
      requestBody: %RequestBody{
        description: "Message parameters",
        content: %{
          "application/json" => %MediaType{
            schema: MessageRequest.schema()
          }
        },
        required: true
      },
      responses: %{
        201 => %Response{description: "Message sent"},
        401 => %Response{description: "Invalid token"}
      }
    }
  end

  defp operation(:get_messages) do
    %Operation{
      tags: ["messages"],
      summary: "Get user messages",
      description: "Retrieves all messages for the authenticated user",
      operationId: "ElixirTest.Controllers.UserController.get_messages",
      security: [%{"bearerAuth" => []}],
      parameters: [
        %Parameter{
          name: "user_id",
          in: :path,
          description: "User ID",
          required: true,
          schema: %Schema{type: :string, format: :uuid}
        }
      ],
      responses: %{
        200 => %Response{
          description: "List of messages",
          content: %{
            "application/json" => %MediaType{
              schema: MessagesResponse.schema()
            }
          }
        },
        401 => %Response{description: "Invalid token"},
        500 => %Response{description: "Failed to retrieve messages"},
        504 => %Response{description: "Request timeout"}
      }
    }
  end
end
