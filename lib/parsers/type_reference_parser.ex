defmodule JS2E.Parsers.TypeReferenceParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema type reference:

      {
        "$ref": "#/definitions/link"
      }

  Into an `JS2E.Types.TypeReference`.
  """

  require Logger

  import JS2E.Parsers.Util,
    only: [
      create_type_dict: 3
    ]

  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserResult
  alias JS2E.Types.TypeReference

  @doc ~S"""
  Returns true if the json subschema represents a reference to another schema.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"$ref" => "#foo"})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(map) :: boolean
  def type?(%{"$ref" => ref}) when is_binary(ref), do: true
  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema type reference into an `JS2E.Types.TypeReference`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t(), URI.t() | nil, TypePath.t(), String.t()) :: ParserResult.t()
  def parse(%{"$ref" => ref}, _parent_id, id, path, name) do
    ref_path =
      ref
      |> to_type_identifier

    type_reference = TypeReference.new(name, ref_path)

    type_reference
    |> create_type_dict(path, id)
    |> ParserResult.new()
  end

  @spec to_type_identifier(String.t()) :: Types.typeIdentifier()
  defp to_type_identifier(path) do
    if URI.parse(path).scheme != nil do
      path |> URI.parse()
    else
      path |> TypePath.from_string()
    end
  end
end
