defmodule JS2E.Parsers.DefinitionsParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a 'definitions' property in a JSON schema or subschema.

      {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "id": "http://example.com/root.json",
        "definitions": {
          "foo": { ... },
          "bar": { ... }
        }
      }

  Into a type dictionary.
  """

  require Logger
  alias JS2E.{Parser, TypePath, Types}

  @doc ~S"""
  Returns true if the json schema contains a 'definitions' property.

  ## Examples

  iex> type?(%{"title" => "A fancy title"})
  false

  iex> type?(%{"definitions" => %{}})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    definitions = schema_node["definitions"]
    is_map(definitions)
  end

  @doc ~S"""
  Parses a JSON schema 'definitions' property into a map of types.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, parent_id, _id, path, _name) do
    Logger.debug "Parsing '#{inspect path}' as definitions"

    child_path =
      path
      |> TypePath.add_child("definitions")

    definitions_type_dict =
      schema_node
      |> Map.get("definitions")
      |> Enum.reduce(%{}, fn({child_name, child_node}, type_dict) ->

      child_types =
        child_node
        |> Parser.parse_type(parent_id, child_path, child_name)

      Map.merge(type_dict, child_types)
    end)
    Logger.debug "definitions, parsed: #{inspect definitions_type_dict}"

    definitions_type_dict
  end

end
