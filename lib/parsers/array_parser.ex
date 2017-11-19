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
  import JS2E.Parsers.Util, only: [
    create_type_dict: 3,
    parse_type: 4
  ]
  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserResult
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
  @spec type?(Types.schemaNode) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    items = schema_node["items"]
    type == "array" && is_map(items)
  end

  @doc ~S"""
  Parses a JSON schema array type into an `JS2E.Types.ArrayType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.schemaNode, URI.t, URI.t | nil, TypePath.t, String.t)
  :: ParserResult.t
  def parse(schema_node, parent_id, id, path, name) do

    items_abs_path =
      path
      |> TypePath.add_child("items")

    items_result =
      schema_node
      |> Map.get("items")
      |> parse_type(parent_id, path, "items")

    array_type = ArrayType.new(name, path, items_abs_path)

    array_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(items_result)
  end

end
