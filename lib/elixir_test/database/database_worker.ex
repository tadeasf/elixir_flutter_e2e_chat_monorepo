defmodule ElixirTest.Database.DatabaseWorker do
  use GenServer
  require Logger

  @max_retries 3
  @retry_delay 1000 # 1 second

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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

  def find(collection, query) do
    GenServer.call(__MODULE__, {:find, collection, query})
  end

  def delete_many(collection, query) do
    GenServer.call(__MODULE__, {:delete_many, collection, query})
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    {:ok, %{retries: %{}}}
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
  def handle_call({:find, collection, query}, _from, state) do
    case do_with_retry(fn ->
      Mongo.find(:mongo, collection, query)
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
end
