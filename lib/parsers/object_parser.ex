defmodule JS2E.Parsers.ObjectParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema object type:

      {
        "type": "object",
        "properties": {
          "color": {
            "$ref": "#/color"
          },
          "title": {
            "type": "string"
          },
          "radius": {
            "type": "number"
          }
        },
        "required": [ "color", "radius" ]
      }

  Into an `JS2E.Types.ObjectType`
  """

  require Logger

  import JS2E.Parsers.Util,
    only: [
      create_type_dict: 3,
      parse_type: 4
    ]

  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserResult
  alias JS2E.Types.ObjectType

  @doc ~S"""
  Returns true if the json subschema represents an allOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => "object"})
  false

  iex> anObject = %{"type" => "object",
  ...>              "properties" => %{"name" => %{"type" => "string"}}}
  iex> type?(anObject)
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    properties = schema_node["properties"]
    type == "object" && is_map(properties)
  end

  @doc ~S"""
  Parses a JSON schema object type into an `JS2E.Types.ObjectType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.schemaNode(), URI.t(), URI.t(), TypePath.t(), String.t()) :: ParserResult.t()
  def parse(schema_node, parent_id, id, path, name) do
    required = Map.get(schema_node, "required", [])

    child_path = TypePath.add_child(path, "properties")

    child_types_result =
      schema_node
      |> Map.get("properties")
      |> parse_child_types(parent_id, child_path)

    type_dict = create_property_dict(child_types_result.type_dict, child_path)

    object_type = ObjectType.new(name, path, type_dict, required)

    object_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(child_types_result)
  end

  @spec parse_child_types(map, URI.t(), TypePath.t()) :: ParserResult.t()
  defp parse_child_types(node_properties, parent_id, child_path) do
    init_result = ParserResult.new()

    node_properties
    |> Enum.reduce(init_result, fn {child_name, child_node}, acc_result ->
      child_types = parse_type(child_node, parent_id, child_path, child_name)
      ParserResult.merge(acc_result, child_types)
    end)
  end

  @doc ~S"""
  Creates a property dictionary based on a type dictionary and a type path.

  ## Examples

      iex> type_dict = %{}
      ...> path = JS2E.TypePath.from_string("#")
      ...> JS2E.Parsers.ObjectParser.create_property_dict(type_dict, path)
      %{}

  """
  @spec create_property_dict(Types.typeDictionary(), TypePath.t()) :: Types.propertyDictionary()
  def create_property_dict(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn {child_path, child_type}, acc_property_dict ->
      child_type_path = TypePath.add_child(path, child_type.name)

      if child_type_path == TypePath.from_string(child_path) do
        child_property_dict = %{child_type.name => child_type_path}
        Map.merge(acc_property_dict, child_property_dict)
      else
        acc_property_dict
      end
    end)
  end
end
