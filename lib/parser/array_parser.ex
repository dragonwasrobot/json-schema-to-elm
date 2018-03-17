defmodule JS2E.Parser.ArrayParser do
  @behaviour JS2E.Parser.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema array type:

      {
        "type": "array",
        "items": {
          "$ref": "#/definitions/rectangle"
        }
      }

  Into an `JS2E.Types.ArrayType`.
  """

  require Logger

  alias JS2E.{Types, TypePath}
  alias JS2E.Parser.{Util, ParserResult}
  alias JS2E.Types.ArrayType

  @doc ~S"""
  Returns true if the json subschema represents an array type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => "array"})
  false

  iex> type?(%{"type" => "array", "items" => %{"$ref" => "#foo"}})
  true

  """
  @impl JS2E.Parser.ParserBehaviour
  @spec type?(Types.schemaNode()) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    items = schema_node["items"]
    type == "array" && is_map(items)
  end

  @doc ~S"""
  Parses a JSON schema array type into an `JS2E.Types.ArrayType`.
  """
  @impl JS2E.Parser.ParserBehaviour
  @spec parse(
          Types.schemaNode(),
          URI.t(),
          URI.t() | nil,
          TypePath.t(),
          String.t()
        ) :: ParserResult.t()
  def parse(schema_node, parent_id, id, path, name) do
    items_abs_path =
      path
      |> TypePath.add_child("items")

    items_result =
      schema_node
      |> Map.get("items")
      |> Util.parse_type(parent_id, path, "items")

    array_type = ArrayType.new(name, path, items_abs_path)

    array_type
    |> Util.create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(items_result)
  end
end
