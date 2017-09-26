defmodule JS2E.Parsers.ArrayParser do
  @behaviour JS2E.Parsers.ParserBehaviour
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
  alias JS2E.{Parser, TypePath, Types}
  alias JS2E.Parsers.Util
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
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    items = schema_node["items"]
    type == "array" && is_map(items)
  end

  @doc ~S"""
  Parses a JSON schema array type into an `JS2E.Types.ArrayType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as ArrayType"

    items_abs_path =
      path
      |> TypePath.add_child("items")

    items_type_dict =
      schema_node
      |> Map.get("items")
      |> Parser.parse_type(parent_id, path, "items")

    array_type = ArrayType.new(name, path, items_abs_path)
    Logger.debug "Parsed array type: #{inspect array_type}"

    array_type
    |> Util.create_type_dict(path, id)
    |> Map.merge(items_type_dict)
  end

end
