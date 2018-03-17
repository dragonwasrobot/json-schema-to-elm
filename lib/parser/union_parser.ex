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

  import JS2E.Parsers.Util,
    only: [
      create_type_dict: 3
    ]

  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserResult
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
  @spec type?(Types.schemaNode()) :: boolean
  def type?(%{"type" => types}) when is_list(types), do: true
  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema union type into an `JS2E.Types.UnionType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t(), URI.t(), TypePath.t(), String.t()) ::
          ParserResult.t()
  def parse(%{"type" => types}, _parent_id, id, path, name) do
    union_type = UnionType.new(name, path, types)

    union_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
  end
end
