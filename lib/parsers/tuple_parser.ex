defmodule JS2E.Parsers.TupleParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema array type:

      {
        "type": "array",
        "items": [
          { "$ref": "#/rectangle" },
          { "$ref": "#/circle" }
        ]
      }

  Into a `JS2E.Types.TupleType`.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.TupleType

  @doc ~S"""
  Returns true if the json subschema represents a tuple type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => "array"})
  false

  iex> aTuple = %{"type" => "array",
  ...>            "items" => [%{"$ref" => "#foo"}, %{"$ref" => "#bar"}]}
  iex> type?(aTuple)
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    items = schema_node["items"]
    type == "array" && is_list(items)
  end

  @doc ~S"""
  Parses a JSON schema array type into an `JS2E.Types.TupleType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as TupleType"

    descendants_types_dict =
      schema_node
      |> Map.get("items")
      |> create_descendants_type_dict(parent_id, path)
    Logger.debug "Descendants types dict: #{inspect descendants_types_dict}"

    tuple_types =
      descendants_types_dict
      |> create_types_list(path)
    Logger.debug "Tuple types: #{inspect tuple_types}"

    tuple_type = TupleType.new(name, path, tuple_types)
    Logger.debug "Parsed tuple type: #{inspect tuple_type}"

    tuple_type
    |> create_type_dict(path, id)
    |> Map.merge(descendants_types_dict)
  end

end
