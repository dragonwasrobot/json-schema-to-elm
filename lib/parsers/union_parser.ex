defmodule JS2E.Parsers.UnionParser do
  @moduledoc """
  Parses a JSON schema union type:

      {
        "type": ["number", "integer", "null"]
      }

  Into an `JS2E.Types.UnionType`.
  """

  require Logger
  alias JS2E.Parsers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.UnionType

  @doc ~S"""
  Parses a JSON schema union type into an `JS2E.Types.UnionType`.
  """
  @spec parse(map, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as union type"

    types = schema_node["type"]
    union_type = %UnionType{name: name,
                            path: path,
                            types: types}
    Logger.debug "Parsed union type: #{inspect union_type}"

    union_type
    |> Util.create_type_dict(path, id)
  end

end
