defmodule JS2E.Parsers.UnionParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema union type:

      {
        "type": ["number", "integer", "null"]
      }

  Into an `JS2E.Types.UnionType`.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.UnionType

  @doc ~S"""
  Returns true if the json subschema represents a union type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => ["number", "integer", "string"]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    is_list(type)
  end

  @doc ~S"""
  Parses a JSON schema union type into an `JS2E.Types.UnionType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, _parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as union type"

    types = schema_node["type"]
    union_type = UnionType.new(name, path, types)
    Logger.debug "Parsed union type: #{inspect union_type}"

    union_type
    |> create_type_dict(path, id)
  end

end
