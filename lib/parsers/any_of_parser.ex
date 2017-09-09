defmodule JS2E.Parsers.AnyOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema anyOf type:

      {
        "anyOf": [
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

  Into an `JS2E.Types.AnyOfType`.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.AnyOfType

  @doc ~S"""
  Parses a JSON schema anyOf type into an `JS2E.Types.AnyOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as anyOf type"

    descendants_types_dict =
      schema_node
      |> Map.get("anyOf")
      |> create_descendants_type_dict(parent_id, path)
    Logger.debug "Descendants types dict: #{inspect descendants_types_dict}"

    any_of_types =
      descendants_types_dict
      |> create_types_list(path)
    Logger.debug "AnyOf types: #{inspect any_of_types}"

    any_of_type = AnyOfType.new(name, path, any_of_types)
    Logger.debug "Parsed anyOf type: #{inspect any_of_type}"

    any_of_type
    |> create_type_dict(path, id)
    |> Map.merge(descendants_types_dict)
  end

end
