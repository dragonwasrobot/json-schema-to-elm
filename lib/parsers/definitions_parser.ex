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
  import JS2E.Parsers.Util, only: [
    parse_type: 4
  ]
  alias JS2E.TypePath
  alias JS2E.Parsers.ParserResult

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
  def type?(%{"definitions" => definitions})
  when is_map(definitions), do: true
  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema 'definitions' property into a map of types.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: ParserResult.t
  def parse(%{"definitions" => definitions}, parent_id, _id, path, _name) do

    child_path =
      path
      |> TypePath.add_child("definitions")

    init_result = ParserResult.new()
    definitions_types_result =
      definitions
      |> Enum.reduce(init_result, fn({child_name, child_node}, acc_result) ->
      child_types = parse_type(child_node, parent_id, child_path, child_name)
      ParserResult.merge(acc_result, child_types)
    end)

    definitions_types_result
  end

end
