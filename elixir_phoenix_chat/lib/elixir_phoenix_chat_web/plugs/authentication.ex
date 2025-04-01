defmodule ElixirPhoenixChatWeb.Plugs.Authentication do
  @moduledoc """
  Plug for verifying JWT tokens in API requests.
  """

  import Plug.Conn
  require Logger

  alias ElixirPhoenixChat.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with {conn, token} <- get_token(conn),
         {:ok, claims} <- Auth.verify_token(token) do
      # Add current user claims to conn assigns
      conn
      |> assign(:current_user_id, claims["user_id"])
      |> assign(:token_claims, claims)
    else
      {:error, :missing_token} ->
        handle_unauthorized(conn, "Missing authorization token")
      {:error, _} ->
        handle_unauthorized(conn, "Invalid token")
      _ ->
        handle_unauthorized(conn, "Unauthorized")
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {conn, token}
      _ -> {:error, :missing_token}
    end
  end

  defp handle_unauthorized(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: message}))
    |> halt()
  end
end
