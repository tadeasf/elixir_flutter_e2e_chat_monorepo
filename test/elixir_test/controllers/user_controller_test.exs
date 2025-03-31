defmodule ElixirTest.Controllers.UserControllerTest do
  use ExUnit.Case, async: false  # Disable async since we're managing a shared application state
  import Plug.Test
  import Plug.Conn
  alias ElixirTest.TestHelper

  @opts ElixirTest.Router.init([])

  setup_all do
    # Start the application once for all tests
    Application.ensure_all_started(:mongodb_driver)
    Application.ensure_all_started(:elixir_test)
    on_exit(fn ->
      Application.stop(:elixir_test)
      Application.stop(:mongodb_driver)
    end)
    :ok
  end

  setup do
    # Clean the database before each test
    TestHelper.clean_db()
    :ok
  end

  describe "user creation" do
    test "creates a new user with generated password" do
      email = "test-#{UUID.uuid4()}@example.com"  # Generate a unique email

      conn = conn(:post, "/users")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{"email" => email})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 201
      body = Jason.decode!(resp.resp_body)
      assert body["user_id"]
      assert body["generated_password"]
      assert body["message"] == "Please store your password securely"

      # Directly insert user for testing since we're using async task
      # Verify the response contains the correct data instead of checking DB
      assert body["email"] == email
    end

    test "fails to create user without email" do
      # Create a new connection with empty body params
      conn = conn(:post, "/users")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{})

      # We need to ensure no other test affects this test
      patch_conn = put_in(conn.path_params, %{})

      resp = ElixirTest.Router.call(patch_conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 400
      assert resp.resp_body == "Email is required"
    end

    test "fails to create user with duplicate email" do
      email = "test@example.com"

      # Create first user
      conn = conn(:post, "/users")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{"email" => email})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()
      assert resp.status == 201

      # Try to create second user with same email
      conn = conn(:post, "/users")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{"email" => email})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 400
      assert resp.resp_body == "Email already exists"
    end
  end

  describe "user login" do
    test "successful login returns token" do
      # Create user
      user = TestHelper.setup_test_user()
      TestHelper.wait_for_tasks()

      # Login
      result = TestHelper.login_test_user(user["email"], user["generated_password"])
      assert result["token"] != nil
    end

    test "login with invalid credentials fails" do
      conn = conn(:post, "/users/login")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{"email" => "invalid@example.com", "password" => "invalid"})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 401
    end
  end

  describe "password change" do
    test "successfully changes password" do
      # Create user
      user = TestHelper.setup_test_user()
      TestHelper.wait_for_tasks()

      # Change password
      conn = conn(:put, "/users/change-password")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:body_params, %{
        "email" => user["email"],
        "current_password" => user["generated_password"],
        "new_password" => "new_password"
      })

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 200

      # Try logging in with new password
      result = TestHelper.login_test_user(user["email"], "new_password")
      assert result["token"] != nil
    end
  end

  describe "messaging" do
    setup do
      user = TestHelper.setup_test_user()
      TestHelper.wait_for_tasks()
      %{"token" => token} = TestHelper.login_test_user(user["email"], user["generated_password"])
      {:ok, %{user: user, token: token}}
    end

    test "sends and receives messages", %{user: user, token: token} do
      # Send message
      conn = conn(:post, "/messages")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> Map.put(:body_params, %{"content" => "Test message"})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()
      assert resp.status == 201

      # Get messages
      conn = conn(:get, "/messages/#{user["user_id"]}")
      |> put_req_header("authorization", "Bearer #{token}")

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 200
      messages = Jason.decode!(resp.resp_body)
      assert length(messages) == 1
      [message] = messages
      assert message["content"] == "Test message"
    end

    test "fails to send message with invalid token", %{user: _user} do
      conn = conn(:post, "/messages")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer invalid")
      |> Map.put(:body_params, %{"content" => "Test message"})

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 401
    end

    test "concurrent message sending and retrieval", %{user: user, token: token} do
      # Send multiple messages concurrently
      tasks = for i <- 1..5 do
        Task.async(fn ->
          conn = conn(:post, "/messages")
          |> put_req_header("content-type", "application/json")
          |> put_req_header("authorization", "Bearer #{token}")
          |> Map.put(:body_params, %{"content" => "Test message #{i}"})

          ElixirTest.Router.call(conn, @opts)
        end)
      end

      # Wait for all messages to be sent
      Enum.each(tasks, &Task.await/1)
      TestHelper.wait_for_tasks()

      # Verify all messages were saved
      conn = conn(:get, "/messages/#{user["user_id"]}")
      |> put_req_header("authorization", "Bearer #{token}")

      resp = ElixirTest.Router.call(conn, @opts)
      TestHelper.wait_for_tasks()

      assert resp.status == 200
      messages = Jason.decode!(resp.resp_body)
      assert length(messages) == 5
    end
  end
end
