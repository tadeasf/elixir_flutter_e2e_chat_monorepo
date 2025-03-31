defmodule Mix.Tasks.EncryptMessages do
  use Mix.Task
  require Logger

  @shortdoc "Encrypt all existing messages in the database"

  def run(_) do
    # Start required applications
    [:mongodb_driver, :crypto]
    |> Enum.each(&Application.ensure_all_started/1)

    # Start our application
    {:ok, _} = Application.ensure_all_started(:elixir_phoenix_chat)

    # Import the encryption module
    alias ElixirPhoenixChat.Utils.Encryption
    alias ElixirPhoenixChat.Repo

    Logger.info("Starting message encryption migration...")

    # Get all messages
    case Repo.find("messages", %{}) do
      {:ok, messages} ->
        total = length(messages)
        Logger.info("Found #{total} messages to process")

        # Track stats
        stats = %{
          total: total,
          encrypted: 0,
          already_encrypted: 0,
          errors: 0
        }

        # Process each message
        stats = Enum.reduce(messages, stats, fn message, acc ->
          try do
            if !Map.has_key?(message, "content") do
              Logger.warning("Message #{message["_id"]} has no content field")
              Map.update!(acc, :errors, &(&1 + 1))
            else
              content = message["content"]

              if Encryption.is_encrypted?(content) do
                Logger.debug("Message #{message["_id"]} is already encrypted")
                Map.update!(acc, :already_encrypted, &(&1 + 1))
              else
                # Encrypt the content
                encrypted_content = Encryption.encrypt(content)

                # Update the message
                case Repo.update("messages",
                  %{"_id" => message["_id"]},
                  %{"$set" => %{"content" => encrypted_content}}) do
                  {:ok, _} ->
                    Logger.debug("Successfully encrypted message #{message["_id"]}")
                    Map.update!(acc, :encrypted, &(&1 + 1))
                  {:error, err} ->
                    Logger.error("Failed to update message #{message["_id"]}: #{inspect(err)}")
                    Map.update!(acc, :errors, &(&1 + 1))
                end
              end
            end
          rescue
            e ->
              Logger.error("Error processing message #{message["_id"]}: #{inspect(e)}")
              Map.update!(acc, :errors, &(&1 + 1))
          end
        end)

        # Log summary
        Logger.info("Message encryption migration complete:")
        Logger.info("  Total messages: #{stats.total}")
        Logger.info("  Newly encrypted: #{stats.encrypted}")
        Logger.info("  Already encrypted: #{stats.already_encrypted}")
        Logger.info("  Errors: #{stats.errors}")

      {:error, err} ->
        Logger.error("Failed to retrieve messages: #{inspect(err)}")
    end
  end
end
