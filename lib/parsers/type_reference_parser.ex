defmodule JS2E.Parsers.TypeReferenceParser do
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
  @spec parse(map, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse(schema_node, id, path, name) do
    Logger.debug "parsing '#{inspect path}' as TypeReference"

    ref_type_path =
      schema_node
      |> Map.get("$ref")
      |> TypePath.from_string

    type_reference = %TypeReference{name: name, path: ref_type_path}
    Logger.debug "Parsed type reference: #{inspect type_reference}"

    type_reference
    |> Util.create_type_dict(path, id)
  end

end
