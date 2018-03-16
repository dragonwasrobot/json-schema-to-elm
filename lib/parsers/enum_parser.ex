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

  import JS2E.Parsers.Util,
    only: [
      create_type_dict: 3
    ]

  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserResult
  alias JS2E.Types.EnumType

  @doc ~S"""
  Returns true if the json subschema represents an enum type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"enum" => ["red", "yellow", "green"], "type" => "string"})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(Types.schemaNode()) :: boolean
  def type?(%{"enum" => enum, "type" => type})
      when is_list(enum) and is_binary(type),
      do: true

  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema enum type into an `JS2E.Types.EnumType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.schemaNode(), URI.t(), URI.t() | nil, TypePath.t(), String.t()) ::
          ParserResult.t()
  def parse(%{"enum" => enum, "type" => type}, _parent_id, id, path, name) do
    # TODO: Check that the enum values all have the same type

    enum_type = EnumType.new(name, path, type, enum)

    enum_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
  end
end
