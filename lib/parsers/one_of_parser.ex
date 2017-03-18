defmodule JS2E.Parsers.OneOfParser do
  @moduledoc ~S"""
  Parses a JSON schema oneOf type:

      {
        "oneOf": [
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
          },
          {
            "type": "string"
          }
        ]
      }

  Into an `JS2E.Types.OneOfType`.
  """

  require Logger
  alias JS2E.{Types, TypePath, Parser}
  alias JS2E.Parsers.Util
  alias JS2E.Types.OneOfType

  @doc ~S"""
  Parses a JSON schema oneOf type into an `JS2E.Types.OneOfType`.
  """
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as oneOf type"

    descendants_types_dict =
      schema_node
      |> Map.get("oneOf")
      |> create_descendants_type_dict(parent_id, path)
    Logger.debug "Descendants types dict: #{inspect descendants_types_dict}"

    one_of_types =
      descendants_types_dict
      |> create_types_list(path)
    Logger.debug "OneOf types: #{inspect one_of_types}"

    one_of_type = %OneOfType{name: name,
                             path: path,
                             types: one_of_types}
    Logger.debug "Parsed oneOf type: #{inspect one_of_type}"

    one_of_type
    |> Util.create_type_dict(path, id)
    |> Map.merge(descendants_types_dict)
  end

  @spec create_descendants_type_dict([map], URI.t, TypePath.t)
  :: Types.typeDictionary
  defp create_descendants_type_dict(types, parent_id, path) do
    types
    |> Enum.reduce({%{}, 0}, fn(child_node, {type_dict, idx}) ->

      child_name = "#{idx}"
      child_types = Parser.parse_type(child_node, parent_id, path, child_name)

      {Map.merge(type_dict, child_types), idx + 1}
    end)
    |> elem(0)
  end

  @spec create_types_list(Types.typeDictionary, TypePath.t) :: [String.t]
  defp create_types_list(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn({child_abs_path, child_type}, reference_dict) ->

      child_path = TypePath.add_child(path, child_type.name)

      if child_path == TypePath.from_string(child_abs_path) do
        Map.merge(reference_dict, %{child_type.name => child_abs_path})
      else
        reference_dict
      end
    end)
    |> Map.values()
  end

end
