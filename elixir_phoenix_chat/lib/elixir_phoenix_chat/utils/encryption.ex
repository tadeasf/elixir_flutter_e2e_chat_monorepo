defmodule ElixirPhoenixChat.Utils.Encryption do
  @moduledoc """
  Utilities for encrypting/decrypting sensitive data.
  """
  require Logger

  @doc """
  Encrypts a string.
  """
  def encrypt(plaintext) when is_binary(plaintext) do
    # Instead of using Cloak.Ecto.Binary.encrypt, use a direct encryption approach
    key = get_encryption_key()
    iv = :crypto.strong_rand_bytes(16)

    {ciphertext, tag} = :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      iv,
      plaintext,
      "",  # Associated data (none in this case)
      true  # Encrypt mode
    )

    # Format: "enc:{base64_iv}:{base64_tag}:{base64_ciphertext}"
    "enc:" <> Base.encode64(iv) <> ":" <> Base.encode64(tag) <> ":" <> Base.encode64(ciphertext)
  end

  @doc """
  Decrypts a string encrypted with encrypt/1.
  """
  def decrypt(encrypted_text) when is_binary(encrypted_text) do
    case String.split(encrypted_text, ":", parts: 4) do
      ["enc", iv_b64, tag_b64, ciphertext_b64] ->
        try do
          iv = Base.decode64!(iv_b64)
          tag = Base.decode64!(tag_b64)
          ciphertext = Base.decode64!(ciphertext_b64)
          key = get_encryption_key()

          :crypto.crypto_one_time_aead(
            :aes_256_gcm,
            key,
            iv,
            ciphertext,
            "",  # Associated data (none in this case)
            tag,
            false  # Decrypt mode
          )
        rescue
          e ->
            Logger.error("Failed to decrypt: #{inspect(e)}")
            nil
        end
      _ ->
        if String.starts_with?(encrypted_text, "cloak:") do
          Logger.warning("Legacy cloak format detected but not supported")
        end
        nil
    end
  end

  @doc """
  Migrates unencrypted messages to encrypted format.
  """
  def migrate_messages do
    {:ok, messages} = ElixirPhoenixChat.Repo.find("messages", %{})

    Enum.each(messages, fn message ->
      if Map.has_key?(message, "content") && !is_encrypted?(message["content"]) do
        encrypted_content = encrypt(message["content"])

        ElixirPhoenixChat.Repo.update(
          "messages",
          %{"_id" => message["_id"]},
          %{"$set" => %{"content" => encrypted_content}}
        )
      end
    end)
  end

  @doc """
  Determines if a value is already encrypted.
  """
  def is_encrypted?(binary) when is_binary(binary) do
    # Check for our encryption prefix
    String.starts_with?(binary, "enc:")
  end

  def is_encrypted?(_), do: false

  # Get encryption key from environment or config
  defp get_encryption_key do
    key_string = System.get_env("ENCRYPTION_KEY") ||
                 Application.get_env(:elixir_phoenix_chat, :encryption_key)

    if is_nil(key_string) do
      raise "Encryption key not found in environment or config"
    end

    # If key is in Base64 format, decode it
    if String.contains?(key_string, ["+", "/", "="]) do
      case Base.decode64(key_string) do
        {:ok, key} -> key
        _ -> hash_key(key_string)
      end
    else
      # Convert string to 32-byte key (for AES-256)
      hash_key(key_string)
    end
  end

  # Convert any string to a 32-byte key using SHA-256
  defp hash_key(string) do
    :crypto.hash(:sha256, string)
  end
end
