defmodule JS2E.RootParser do
  @moduledoc ~S"""
  Contains logic for verifying the schema version of a JSON schema file.
  """

  require Logger
  import JS2E.Parsers.Util
  alias JS2E.Parsers.{ArrayParser, DefinitionsParser,
                      ObjectParser, TupleParser, TypeReferenceParser}
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.SchemaDefinition

  @spec parse_schema(map, String.t)
  :: {:ok, Types.schemaDictionary} | {:error, [String.t]}
  def parse_schema(root_node, module_name) do

    with {:ok, _schema_version} <- parse_schema_version(root_node),
         {:ok, schema_id} <- parse_schema_id(root_node)
    do

        title = Map.get(root_node, "title", "")
        description = Map.get(root_node, "description")

        handle_conflict = fn (key, value1, value2) ->
          Logger.error "Collision in type dict, found two values, " <>
            " '#{inspect value1}' and '#{inspect value2}' for key '#{key}'"
          exit(:invalid)
        end

        definitions_type_dict = parse_definitions(root_node, schema_id)
        root_type_dict = parse_root_object(root_node, schema_id, title)

        type_dict =
          %{}
          |> Map.merge(definitions_type_dict, handle_conflict)
          |> Map.merge(root_type_dict, handle_conflict)

        {:ok, %{to_string(schema_id) => SchemaDefinition.new(
               schema_id, title, module_name, description, type_dict)}}

    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec parse_definitions(map, URI.t) :: Types.typeDictionary
  defp parse_definitions(schema_root_node, schema_id) do
    if DefinitionsParser.type?(schema_root_node) do
      schema_root_node
      |> DefinitionsParser.parse(schema_id, nil, ["#"], "")
    else
      %{}
    end
  end

  @spec parse_root_object(map, URI.t, String.t) :: Types.typeDictionary
  defp parse_root_object(schema_root_node, schema_id, _title) do

    type_path = TypePath.from_string("#")
    name = "#"

    cond do
      TypeReferenceParser.type?(schema_root_node) ->
        schema_root_node
        |> TypeReferenceParser.parse(schema_id, schema_id, type_path, name)

      ObjectParser.type?(schema_root_node) ->
        schema_root_node
        |> parse_type(schema_id, [], name)

      TupleParser.type?(schema_root_node) ->
        schema_root_node
        |> parse_type(schema_id, [], name)

      ArrayParser.type?(schema_root_node) ->
        schema_root_node
        |> parse_type(schema_id, [], name)

      true ->
        Logger.debug "Found no valid root object"
        %{}
    end
  end

  @supported_versions [
    "http://json-schema.org/draft-04/schema"
  ]

  @doc ~S"""
  Returns `:ok` if the given JSON schema has a known supported version,
  and an error tuple otherwise.

  ## Examples

      iex> schema = %{"$schema" => "http://json-schema.org/draft-04/schema"}
      iex> parse_schema_version(schema)
      {:ok, "http://json-schema.org/draft-04/schema"}

      iex> schema = %{"$schema" => "http://example.org/my-own-schema"}
      iex> schema |> parse_schema_version() |> elem(0)
      :error

      iex> parse_schema_version(%{})
      {:error, "JSON Schema has no '$schema' keyword"}
  """
  @spec parse_schema_version(map) :: :ok | {:error, String.t}
  def parse_schema_version(%{"$schema" => schema_str}) do

    schema_version = schema_str |> URI.parse |> to_string
    if schema_version in @supported_versions do
      {:ok, schema_version}

    else
      {:error, "Unsupported JSON schema version identifier " <>
        "found in '$schema': '#{schema_str}', " <>
        "supported versions are: #{inspect @supported_versions}"}
    end

  end
  def parse_schema_version(_schema) do
    {:error, "JSON Schema has no '$schema' keyword"}
  end

  @doc ~S"""
  Parses the ID of a JSON schema.

  ## Examples

      iex> parse_schema_id(%{"id" => "http://www.example.com/my-schema"})
      {:ok, URI.parse("http://www.example.com/my-schema")}

      iex> parse_schema_id(%{})
      {:error, "JSON schema has no 'id' property"}

  """
  @spec parse_schema_id(map) :: {:ok, URI.t} | {:error, String.t}
  def parse_schema_id(%{"id" => schema_id}) when is_binary(schema_id) do
    {:ok, URI.parse(schema_id)}
  end
  def parse_schema_id(_) do
    {:error, "JSON schema has no 'id' property"}
  end

end
