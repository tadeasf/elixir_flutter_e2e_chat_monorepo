defmodule ElixirPhoenixChat.Utils.JsonHelpers do
  @moduledoc """
  Helper functions for JSON encoding/decoding with MongoDB BSON support.
  """

  @doc """
  Safely encode a MongoDB document to JSON by converting BSON.ObjectId to strings.
  """
  def encode_mongo_document(document) when is_map(document) do
    document
    |> convert_object_ids()
  end

  @doc """
  Convert all BSON.ObjectId values in a map to strings.
  """
  def convert_object_ids(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {k, convert_value(v)} end)
    |> Enum.into(%{})
  end

  def convert_object_ids(data) when is_list(data) do
    Enum.map(data, &convert_value/1)
  end

  def convert_object_ids(data), do: data

  # Convert different types of values
  defp convert_value(%BSON.ObjectId{} = oid), do: BSON.ObjectId.encode!(oid)
  # Handle DateTime values by converting to ISO8601 strings
  defp convert_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp convert_value(map) when is_map(map), do: convert_object_ids(map)
  defp convert_value(list) when is_list(list), do: convert_object_ids(list)
  defp convert_value(value), do: value
end
