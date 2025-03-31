defmodule ElixirPhoenixChat.Utils.FormatterTest do
  use ExUnit.Case, async: true
  alias ElixirPhoenixChat.Utils.Formatter

  describe "format_changeset_errors/1" do
    test "correctly formats changeset errors" do
      # Create a changeset with errors
      changeset =
        %Ecto.Changeset{
          action: :insert,
          errors: [
            email: {"can't be blank", [validation: :required]},
            password: {"should be at least %{count} character(s)", [count: 6, validation: :length, kind: :min]}
          ],
          valid?: false
        }

      errors = Formatter.format_changeset_errors(changeset)

      assert errors == %{
        email: ["can't be blank"],
        password: ["should be at least 6 character(s)"]
      }
    end
  end
end
