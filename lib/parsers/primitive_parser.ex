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
  import JS2E.Parsers.Util, only: [
    create_type_dict: 3
  ]
  alias JS2E.TypePath
  alias JS2E.Parsers.ParserResult
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
  @spec parse(map, URI.t, URI.t, TypePath.t, String.t) :: ParserResult.t
  def parse(schema_node, _parent_id, id, path, name) do

    type = schema_node["type"]
    primitive_type = PrimitiveType.new(name, path, type)

    primitive_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
  end

end
