defmodule ElixirPhoenixChat.Utils.Formatter do
  @moduledoc """
  Utility functions for formatting and transformation.
  """

  @doc """
  Formats Ecto.Changeset errors into a human-readable map.
  """
  def format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  Converts MongoDB document to a more API-friendly format.
  Removes internal fields and renames ID field.
  """
  def format_mongo_document(document) when is_map(document) do
    document
    |> Map.drop(["__v", "password_hash"])
    |> Map.put("id", document["_id"])
    |> Map.delete("_id")
  end

  def format_mongo_document(documents) when is_list(documents) do
    Enum.map(documents, &format_mongo_document/1)
  end

  @doc """
  Converts atom-keyed map to string-keyed map, which is required for MongoDB.
  """
  def atom_map_to_string_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), atom_value_to_string(v)}
      {k, v} -> {k, atom_value_to_string(v)}
    end)
  end

  defp atom_value_to_string(value) when is_map(value), do: atom_map_to_string_map(value)
  defp atom_value_to_string(value) when is_list(value), do: Enum.map(value, &atom_value_to_string/1)
  defp atom_value_to_string(value), do: value
end
