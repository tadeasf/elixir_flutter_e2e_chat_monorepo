defmodule ElixirPhoenixChat.Utils.AuditLogger do
  @moduledoc """
  Handles security audit logging for the application.
  Stores audit events in MongoDB for future analysis.
  """

  alias ElixirPhoenixChat.Repo
  require Logger

  @audit_collection "audit_logs"

  @doc """
  Logs a security-related event to the audit log.

  ## Parameters
    - event_type: String identifying the type of event
    - metadata: Map of contextual information
    - severity: Atom indicating severity (:info, :warning, :error)
  """
  def log(event_type, metadata, severity \\ :info) do
    # Always include timestamp
    data = Map.merge(metadata, %{
      "event_type" => event_type,
      "timestamp" => DateTime.utc_now(),
      "severity" => severity
    })

    # Store asynchronously to avoid impacting performance
    Task.Supervisor.start_child(ElixirPhoenixChat.TaskSupervisor, fn ->
      case Repo.insert(@audit_collection, data) do
        {:ok, _} ->
          Logger.debug("Audit log created for #{event_type}")
        {:error, error} ->
          Logger.error("Failed to create audit log: #{inspect(error)}")
      end
    end)
  end

  @doc """
  Logs a user authentication event (login attempt, success, failure).
  """
  def log_auth_event(status, user_id, ip_address, metadata \\ %{}) do
    event_data = %{
      "user_id" => user_id,
      "ip_address" => ip_address,
      "status" => status
    }
    |> Map.merge(metadata)

    severity = case status do
      "success" -> :info
      "failure" -> :warning
      _ -> :info
    end

    log("authentication", event_data, severity)
  end

  @doc """
  Logs message-related security events.
  """
  def log_message_event(action, user_id, metadata \\ %{}) do
    event_data = %{
      "user_id" => user_id,
      "action" => action
    }
    |> Map.merge(metadata)

    log("message_security", event_data, :info)
  end

  @doc """
  Retrieve audit logs for a specific user.
  """
  def get_user_audit_logs(user_id, limit \\ 100) do
    Repo.find(@audit_collection, %{"user_id" => user_id}, limit: limit, sort: %{"timestamp" => -1})
  end

  @doc """
  Retrieve security events of a specific type.
  """
  def get_events_by_type(event_type, limit \\ 100) do
    Repo.find(@audit_collection, %{"event_type" => event_type}, limit: limit, sort: %{"timestamp" => -1})
  end
end
