defmodule Mix.Tasks.PhoenixSwagger.Generate do
  use Mix.Task

  @shortdoc "Generate Swagger documentation"

  def run(_) do
    Mix.Task.run("compile")

    # Start applications
    {:ok, _} = Application.ensure_all_started(:phoenix_swagger)
    {:ok, _} = Application.ensure_all_started(:elixir_phoenix_chat)

    # Output file
    output_file = "priv/static/swagger.json"

    # Generate the swagger file
    swagger_info = ElixirPhoenixChatWeb.SwaggerInfo.swagger_info()

    # Create a simple Swagger document since the automatic generation has issues
    swagger = Map.merge(swagger_info, %{
      paths: %{
        "/api/users" => %{
          post: %{
            tags: ["Users"],
            summary: "Register a new user",
            parameters: [
              %{
                name: "user",
                in: "body",
                description: "User registration details",
                required: true,
                schema: %{
                  type: "object",
                  properties: %{
                    email: %{type: "string"},
                    password: %{type: "string"}
                  }
                }
              }
            ],
            responses: %{
              "201" => %{description: "User created successfully"},
              "400" => %{description: "Bad request"}
            }
          }
        },
        "/api/users/login" => %{
          post: %{
            tags: ["Users"],
            summary: "Log in a user",
            parameters: [
              %{
                name: "credentials",
                in: "body",
                description: "User login credentials",
                required: true,
                schema: %{
                  type: "object",
                  properties: %{
                    email: %{type: "string"},
                    password: %{type: "string"}
                  }
                }
              }
            ],
            responses: %{
              "200" => %{description: "Login successful"},
              "401" => %{description: "Unauthorized"}
            }
          }
        },
        "/api/messages" => %{
          post: %{
            tags: ["Messages"],
            summary: "Send a message",
            security: [%{JWT: []}],
            parameters: [
              %{
                name: "message",
                in: "body",
                description: "Message details",
                required: true,
                schema: %{
                  type: "object",
                  properties: %{
                    recipient_id: %{type: "string"},
                    content: %{type: "string"}
                  }
                }
              }
            ],
            responses: %{
              "201" => %{description: "Message sent successfully"},
              "400" => %{description: "Bad request"},
              "401" => %{description: "Unauthorized"}
            }
          },
          get: %{
            tags: ["Messages"],
            summary: "Get user messages",
            security: [%{JWT: []}],
            responses: %{
              "200" => %{description: "List of messages"},
              "401" => %{description: "Unauthorized"}
            }
          }
        }
      }
    })

    File.mkdir_p!(Path.dirname(output_file))
    File.write!(output_file, Jason.encode!(swagger, pretty: true))

    Mix.shell().info("Generated #{output_file}")
  end
end
