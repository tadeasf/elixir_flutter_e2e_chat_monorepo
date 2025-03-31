defmodule ElixirTest.TestHelper do
  import Plug.Conn
  import Plug.Test

  def setup_test_user do
    ensure_app_started()
    email = "test-#{UUID.uuid4()}@example.com"
    conn = conn(:post, "/users")
    |> put_req_header("content-type", "application/json")
    |> Map.put(:body_params, %{"email" => email})

    resp = ElixirTest.Router.call(conn, ElixirTest.Router.init([]))
    # Wait for async operations to complete
    wait_for_tasks()
    result = Jason.decode!(resp.resp_body)
    %{result | "email" => email}  # Add email to the result
  end

  def login_test_user(email, password) do
    ensure_app_started()
    conn = conn(:post, "/users/login")
    |> put_req_header("content-type", "application/json")
    |> Map.put(:body_params, %{"email" => email, "password" => password})

    resp = ElixirTest.Router.call(conn, ElixirTest.Router.init([]))
    # Wait for async operations to complete
    wait_for_tasks()
    Jason.decode!(resp.resp_body)
  end

  def clean_db do
    ensure_app_started()
    # Clean up in parallel
    tasks = [
      Task.async(fn -> Mongo.delete_many(:mongo, "users", %{}) end),
      Task.async(fn -> Mongo.delete_many(:mongo, "messages", %{}) end)
    ]
    Task.await_many(tasks, 5000)
  end

  def wait_for_tasks do
    # Wait for any pending tasks to complete
    # Increased wait time to ensure all tasks complete
    Process.sleep(500)
  end

  defp ensure_app_started do
    case Application.ensure_all_started(:elixir_test) do
      {:ok, _} -> :ok
      {:error, _} ->
        # Try to stop and restart if there was an error
        Application.stop(:elixir_test)
        {:ok, _} = Application.ensure_all_started(:elixir_test)
        :ok
    end
  end
end
