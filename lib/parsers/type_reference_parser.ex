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
  alias JS2E.{TypePath, Types}
  alias JS2E.Parsers.Util
  alias JS2E.Types.TypeReference

  @doc ~S"""
  Parses a JSON schema type reference into an `JS2E.Types.TypeReference`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
  def parse(schema_node, _parent_id, id, path, name) do
    Logger.debug "parsing '#{inspect path}' as TypeReference"

    ref_path =
      schema_node
      |> Map.get("$ref")
      |> to_type_identifier

    type_reference = TypeReference.new(name, ref_path)
    Logger.debug "Parsed type reference: #{inspect type_reference}"

    type_reference
    |> Util.create_type_dict(path, id)
  end

  @spec to_type_identifier(String.t) :: Types.typeIdentifier
  defp to_type_identifier(path) do
    if URI.parse(path).scheme != nil do
      path |> URI.parse
    else
      path |> TypePath.from_string
    end
  end

end
