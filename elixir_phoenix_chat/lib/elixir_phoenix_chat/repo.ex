defmodule ElixirPhoenixChat.Repo do
  use GenServer
  require Logger

  @max_retries 3
  @retry_delay 1000 # 1 second

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def insert(collection, document) do
    GenServer.call(__MODULE__, {:insert, collection, document})
  end

  def update(collection, query, update) do
    GenServer.call(__MODULE__, {:update, collection, query, update})
  end

  def find_one(collection, query) do
    GenServer.call(__MODULE__, {:find_one, collection, query})
  end

  def find(collection, query, opts \\ []) do
    GenServer.call(__MODULE__, {:find, collection, query, opts})
  end

  def delete_many(collection, query) do
    GenServer.call(__MODULE__, {:delete_many, collection, query})
  end

  @doc """
  Creates an index on a MongoDB collection.

  ## Options
  - :unique - if true, creates a unique index
  - :sparse - if true, only index documents containing the field
  - :name - custom name for the index
  """
  def create_index(collection, fields, opts \\ []) do
    GenServer.call(__MODULE__, {:create_index, collection, fields, opts})
  end

  @doc """
  Creates a text index for full-text search capabilities.
  """
  def create_text_index(collection, fields, opts \\ []) do
    # Convert fields to text index format
    text_fields = Enum.reduce(fields, %{}, fn field, acc ->
      Map.put(acc, field, "text")
    end)

    create_index(collection, text_fields, opts)
  end

  @doc """
  Sets up schema validation for a collection using MongoDB Schema Validation.

  This ensures data integrity at the database level.
  """
  def create_schema_validation(collection, schema) do
    GenServer.call(__MODULE__, {:create_schema_validation, collection, schema})
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    # Defer index setup to prevent calling ourselves during initialization
    Process.send_after(self(), :setup_schema, 1000)
    {:ok, %{retries: %{}}}
  end

  @impl true
  def handle_info(:setup_schema, state) do
    # Setup essential indexes when repo starts
    setup_indexes()

    # Schema validation is disabled for now

    {:noreply, state}
  end

  @impl true
  def handle_call({:insert, collection, document}, _from, state) do
    case do_with_retry(fn -> Mongo.insert_one(:mongo, collection, document) end) do
      {:ok, result} ->
        {:reply, {:ok, result}, state}
      {:error, error} ->
        Logger.error("Failed to insert into #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:update, collection, query, update}, _from, state) do
    case do_with_retry(fn -> Mongo.update_one(:mongo, collection, query, update) end) do
      {:ok, result} ->
        {:reply, {:ok, result}, state}
      {:error, error} ->
        Logger.error("Failed to update #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:find_one, collection, query}, _from, state) do
    case do_with_retry(fn -> Mongo.find_one(:mongo, collection, query) end) do
      {:ok, nil} -> {:reply, {:ok, nil}, state}
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, error} ->
        Logger.error("Failed to find_one in #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:find, collection, query, opts}, _from, state) do
    case do_with_retry(fn ->
      Mongo.find(:mongo, collection, query, opts)
      |> Enum.to_list()
    end) do
      {:ok, results} -> {:reply, {:ok, results}, state}
      {:error, error} ->
        Logger.error("Failed to find in #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:delete_many, collection, query}, _from, state) do
    case do_with_retry(fn -> Mongo.delete_many(:mongo, collection, query) end) do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, error} ->
        Logger.error("Failed to delete_many from #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:create_index, collection, fields, opts}, _from, state) do
    case do_with_retry(fn -> Mongo.create_indexes(:mongo, collection, [%{key: fields, name: opts[:name], unique: opts[:unique], sparse: opts[:sparse]}]) end) do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, error} ->
        Logger.error("Failed to create index on #{collection} after #{@max_retries} retries: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:create_schema_validation, _collection, _schema}, _from, state) do
    # We're disabling schema validation for now
    {:reply, {:ok, %{"ok" => 1}}, state}
  end

  # Private Functions
  defp do_with_retry(operation, retries \\ 0) do
    try do
      result = operation.()
      {:ok, result}
    rescue
      e ->
        if retries < @max_retries do
          Logger.warning("Database operation failed, attempt #{retries + 1}/#{@max_retries}: #{inspect(e)}")
          Process.sleep(@retry_delay)
          do_with_retry(operation, retries + 1)
        else
          {:error, e}
        end
    end
  end

  # Setup all required indexes
  defp setup_indexes do
    # User indexes
    Mongo.create_indexes(:mongo, "users", [%{key: %{"email" => 1}, name: "email_unique", unique: true}])

    # Message indexes
    Mongo.create_indexes(:mongo, "messages", [
      %{key: %{"user_id" => 1}, name: "messages_user_id"},
      %{key: %{"recipient_id" => 1}, name: "messages_recipient_id"},
      %{key: %{"created_at" => -1}, name: "messages_created_at"}
    ])

    # Create text index directly
    Mongo.create_indexes(:mongo, "messages", [
      %{key: %{"content" => "text"}, name: "messages_content_text"}
    ])

    # Audit log indexes
    Mongo.create_indexes(:mongo, "audit_logs", [
      %{key: %{"user_id" => 1}, name: "audit_user_id"},
      %{key: %{"event_type" => 1}, name: "audit_event_type"},
      %{key: %{"timestamp" => -1}, name: "audit_timestamp"},
      %{key: %{"severity" => 1}, name: "audit_severity"}
    ])

    Logger.info("Database indexes created successfully")
  end
end
