defmodule ElixirPhoenixChatWeb.SwaggerInfo do
  @moduledoc """
  Provides API documentation metadata for Phoenix Swagger
  """

  def swagger_info do
    %{
      info: %{
        version: "1.0.0",
        title: "Elixir Phoenix Chat API",
        description: "API for chat application built with Elixir and Phoenix Framework",
        termsOfService: "https://example.com/terms-of-service",
        contact: %{
          name: "API Support",
          email: "support@example.com"
        },
        license: %{
          name: "MIT",
          url: "https://opensource.org/licenses/MIT"
        }
      },
      consumes: ["application/json"],
      produces: ["application/json"],
      securityDefinitions: %{
        JWT: %{
          type: "apiKey",
          in: "header",
          name: "Authorization",
          description: "Add 'Bearer ' + your JWT token to authorize"
        }
      },
      tags: [
        %{name: "Users", description: "User management operations"},
        %{name: "Messages", description: "Message operations"}
      ]
    }
  end
end
