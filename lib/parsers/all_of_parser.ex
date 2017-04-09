defmodule JS2E.Parsers.AllOfParser do
  @moduledoc ~S"""
  Parses a JSON schema allOf type:

      {
        "allOf": [
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

  Into an `JS2E.Types.AllOfType`.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.{Types, TypePath, Parser}
  alias JS2E.Types.AllOfType

  @doc ~S"""
  Parses a JSON schema allOf type into an `JS2E.Types.AllOfType`.
  """
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as allOf type"

    descendants_types_dict =
      schema_node
      |> Map.get("allOf")
      |> create_descendants_type_dict(parent_id, path)
    Logger.debug "Descendants types dict: #{inspect descendants_types_dict}"

    all_of_types =
      descendants_types_dict
      |> create_types_list(path)
    Logger.debug "AllOf types: #{inspect all_of_types}"

    all_of_type = AllOfType.new(name, path, all_of_types)
    Logger.debug "Parsed allOf type: #{inspect all_of_type}"

    all_of_type
    |> create_type_dict(path, id)
    |> Map.merge(descendants_types_dict)
  end

end
