defmodule JS2E.Parser.UnionParser do
  @behaviour JS2E.Parser.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema union type:

      {
        "type": ["number", "integer", "null"]
      }

  Into an `JS2E.Types.UnionType`.
  """

  require Logger
  alias JS2E.{Parser, TypePath, Types}
  alias Parser.{ParserResult, Util}
  alias Types.UnionType

  @doc ~S"""
  Returns true if the json subschema represents a union type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"type" => ["number", "integer", "string"]})
  true

  """
  @impl JS2E.Parser.ParserBehaviour
  @spec type?(Types.schemaNode()) :: boolean
  def type?(%{"type" => types}) when is_list(types), do: true
  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema union type into an `JS2E.Types.UnionType`.
  """
  @impl JS2E.Parser.ParserBehaviour
  @spec parse(map, URI.t(), URI.t(), TypePath.t(), String.t()) ::
          ParserResult.t()
  def parse(%{"type" => types}, _parent_id, id, path, name) do
    union_type = UnionType.new(name, path, types)

    union_type
    |> Util.create_type_dict(path, id)
    |> ParserResult.new()
  end
end
