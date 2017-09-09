defmodule JS2E.Parsers.EnumParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parse a JSON schema enum type:

      {
        "type": "string",
        "enum": ["none", "green", "orange", "blue", "yellow", "red"]
      }

  Into an `JS2E.Types.EnumType`.
  """

  require Logger
  alias JS2E.{TypePath, Types}
  alias JS2E.Parsers.Util
  alias JS2E.Types.EnumType

  @doc ~S"""
  Parses a JSON schema enum type into an `JS2E.Types.EnumType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, _parent_id, id, path, name) do
    Logger.debug "parsing '#{inspect path}' as EnumType"

    type = schema_node["type"]
    enum_values = schema_node["enum"]
    enum_type = EnumType.new(name, path, type, enum_values)
    Logger.debug "Parsed enum type: #{inspect enum_type}"

    enum_type
    |> Util.create_type_dict(path, id)
  end

end
