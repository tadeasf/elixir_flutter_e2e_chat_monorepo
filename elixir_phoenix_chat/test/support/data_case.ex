defmodule ElixirPhoenixChat.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias ElixirPhoenixChat.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import ElixirPhoenixChat.DataCase
    end
  end

  setup _tags do
    # No special sandbox setup needed for MongoDB in test
    :ok
  end

  @doc """
  Sets up the MongoDB context for tests.
  """
  def setup_sandbox(_tags) do
    # MongoDB doesn't have a sandbox mode like SQL databases
    # For tests, we can clean collections before/after tests
    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
