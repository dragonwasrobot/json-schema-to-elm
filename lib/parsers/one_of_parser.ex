defmodule JS2E.Parsers.OneOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
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
  import JS2E.Parsers.Util
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.OneOfType

  @doc ~S"""
  Returns true if the json subschema represents an oneOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"oneOf" => []})
  false

  iex> type?(%{"oneOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    one_of = schema_node["oneOf"]
    is_list(one_of) && length(one_of) > 0
  end

  @doc ~S"""
  Parses a JSON schema oneOf type into an `JS2E.Types.OneOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
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

    one_of_type = OneOfType.new(name, path, one_of_types)
    Logger.debug "Parsed oneOf type: #{inspect one_of_type}"

    one_of_type
    |> create_type_dict(path, id)
    |> Map.merge(descendants_types_dict)
  end

end
