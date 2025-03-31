defmodule ElixirPhoenixChat.Auth do
  use GenServer
  require Logger

  @token_expiry 86400 # 24 hours in seconds

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def generate_token(user_id) do
    token_config = %{
      "user_id" => user_id,
      "exp" => current_time() + @token_expiry
    }

    case Joken.generate_and_sign(%{}, token_config, get_signer()) do
      {:ok, token, _claims} -> token
      {:error, reason} ->
        Logger.error("Failed to generate token: #{inspect(reason)}")
        nil
    end
  end

  def verify_token(token) when is_binary(token) do
    case Joken.verify(token, get_signer()) do
      {:ok, claims} ->
        # Check if token is expired
        if claims["exp"] && claims["exp"] > current_time() do
          {:ok, claims}
        else
          Logger.warning("Token expired: #{inspect(claims)}")
          {:error, :expired_token}
        end
      {:error, reason} ->
        Logger.warning("Invalid token: #{inspect(reason)}")
        {:error, :invalid_token}
    end
  end

  # Handle error cases explicitly
  def verify_token(:missing_token) do
    Logger.warning("Missing token")
    {:error, :missing_token}
  end

  def verify_token(_) do
    Logger.warning("Invalid token format")
    {:error, :invalid_token}
  end

  # Server Callbacks
  @impl true
  def init(_) do
    {:ok, nil}
  end

  # Private Functions
  defp get_signer do
    Joken.Signer.create("HS256", Application.get_env(:joken, :default_signer)[:key_octet])
  end

  defp current_time do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
