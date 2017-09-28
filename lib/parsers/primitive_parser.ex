defmodule JS2E.Parsers.PrimitiveParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema primitive type:

      {
        "type": "string"
      }

  Into an `JS2E.Types.PrimitiveType`.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.PrimitiveType

  @doc ~S"""
  Returns true if the json subschema represents a primitive type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => "object"})
  false

  iex> type?(%{"type" => "boolean"})
  true

  iex> type?(%{"type" => "integer"})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(schema_node) do
    type = schema_node["type"]
    type in ["null", "boolean", "string", "number", "integer"]
  end

  @doc ~S"""
  Parses a JSON schema primitive type into an `JS2E.Types.PrimitiveType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, _parent_id, id, path, name) do
    Logger.debug "Parsing '#{inspect path}' as primitive type"

    type = schema_node["type"]
    primitive_type = PrimitiveType.new(name, path, type)
    Logger.debug "Parsed primitive type: #{inspect primitive_type}"

    primitive_type
    |> create_type_dict(path, id)
  end

end
