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
  import JS2E.Parsers.Util
  alias JS2E.{TypePath, Types}
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
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as ObjectType"

    required = Map.get(schema_node, "required", [])

    descendants_type_dict =
      schema_node
      |> Map.get("properties")
      |> create_descendants_dict(parent_id, path)
    Logger.debug "Descendants types dict: #{inspect descendants_type_dict}"

    property_type_ref_dict = create_property_dict(
      descendants_type_dict, path)
    Logger.debug "Property ref dict: #{inspect property_type_ref_dict}"

    object_type = ObjectType.new(name, path, property_type_ref_dict, required)
    Logger.debug "Parsed object type: #{inspect object_type}"

    object_type
    |> create_type_dict(path, id)
    |> Map.merge(descendants_type_dict)
  end

  @spec create_descendants_dict(map, URI.t, TypePath.t) :: Types.typeDictionary
  defp create_descendants_dict(node_properties, parent_id, path) do
    node_properties
    |> Enum.reduce(%{}, fn({child_name, child_node}, type_dict) ->
      child_types = parse_type(child_node, parent_id, path, child_name)

      Map.merge(type_dict, child_types)
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
  @spec create_property_dict(Types.typeDictionary, TypePath.t)
  :: Types.propertyDictionary
  def create_property_dict(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn({child_path, child_type}, reference_dict) ->
      child_type_path = TypePath.add_child(path, child_type.name)

      if child_type_path == TypePath.from_string(child_path) do
        Map.merge(reference_dict, %{child_type.name => child_type_path})

      else
        reference_dict
      end
    end)
  end

end
