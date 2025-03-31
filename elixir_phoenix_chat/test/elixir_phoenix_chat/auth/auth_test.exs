defmodule ElixirPhoenixChat.AuthTest do
  use ExUnit.Case, async: true
  alias ElixirPhoenixChat.Auth

  describe "token handling" do
    test "generate_token/1 creates a valid token" do
      user_id = Ecto.UUID.generate()
      token = Auth.generate_token(user_id)

      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "verify_token/1 validates a generated token" do
      user_id = Ecto.UUID.generate()
      token = Auth.generate_token(user_id)

      assert {:ok, claims} = Auth.verify_token(token)
      assert claims["user_id"] == user_id
      assert claims["exp"] > DateTime.utc_now() |> DateTime.to_unix()
    end

    test "verify_token/1 rejects invalid tokens" do
      assert {:error, :invalid_token} = Auth.verify_token("invalid_token")
    end
  end
end
