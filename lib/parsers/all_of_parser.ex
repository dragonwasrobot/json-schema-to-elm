defmodule JS2E.Parsers.AllOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
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
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.AllOfType

  @doc ~S"""
  Returns true if the json subschema represents an allOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"allOf" => []})
  false

  iex> type?(%{"allOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    all_of = schema_node["allOf"]
    is_list(all_of) && length(all_of) > 0
  end

  @doc ~S"""
  Parses a JSON schema allOf type into an `JS2E.Types.AllOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
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
