defmodule JS2E.Parsers.PrimitiveParser do
  @moduledoc ~S"""
  Parses a JSON schema primitive type:

      {
        "type": "string"
      }

  Into an `JS2E.Types.PrimitiveType`.
  """

  require Logger
  alias JS2E.{TypePath, Types}
  alias JS2E.Parsers.Util
  alias JS2E.Types.PrimitiveType

  @doc ~S"""
  Parses a JSON schema primitive type into an `JS2E.Types.PrimitiveType`.
  """
  @spec parse(map, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as primitive type"

    type = schema_node["type"]
    primitive_type = %PrimitiveType{name: name,
                                    path: path,
                                    type: type}

    Logger.debug "Parsed primitive type: #{inspect primitive_type}"

    primitive_type
    |> Util.create_type_dict(path, id)
  end

end
