defmodule JS2E.Parser do
  @moduledoc ~S"""
  Parses JSON schema files into an intermediate representation to be used for
  e.g. printing elm decoders.
  """

  require Logger
  alias JS2E.Parsers.{ArrayParser, UnionParser, PrimitiveParser,
                      DefinitionsParser, OneOfParser, ObjectParser,
                      EnumParser, TypeReferenceParser}
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.SchemaDefinition

  @type nodeParser :: (
    map, URI.t, URI.t, TypePath.t, String.t -> Types.typeDictionary
  )

  @supported_versions ["http://json-schema.org/draft-04/schema"]

  @spec parse_schema_file(String.t) :: Types.schemaDictionary
  def parse_schema_file(json_schema_path) do
    json_schema_path
    |> File.read!
    |> Poison.decode!
    |> parse_schema
  end

  @spec parse_schema(map) :: Types.schemaDictionary
  def parse_schema(schema_root_node) do

    if not supported_schema_version?(schema_root_node) do
      exit(:bad_version)
    end

    schema_id = Map.fetch!(schema_root_node, "id")
    title = Map.get(schema_root_node, "title", "")
    description = Map.get(schema_root_node, "description")

    handle_conflict = fn (key, value1, value2) ->
      Logger.error "Collision in type dict, found two values, " <>
        " '#{inspect value1}' and '#{inspect value2}' for key '#{key}'"
      exit(:invalid)
    end

    definitions = parse_definitions(schema_root_node, schema_id)
    root = parse_root_object(schema_root_node, schema_id, title)

    types =
      %{}
      |> Map.merge(definitions, handle_conflict)
      |> Map.merge(root, handle_conflict)

    %{schema_id =>
      %SchemaDefinition{id: schema_id,
                        title: title,
                        description: description,
                        types: types}}
  end

  @spec parse_definitions(map, URI.t) :: Types.typeDictionary
  defp parse_definitions(schema_root_node, schema_id) do
    if definitions?(schema_root_node) do
      schema_root_node |> DefinitionsParser.parse(schema_id, nil, ["#"], "")
    else
      %{}
    end
  end

  @spec parse_root_object(map, URI.t, String.t) :: Types.typeDictionary
  defp parse_root_object(schema_root_node, schema_id, title) do

    cond do
      ref_type?(schema_root_node) ->
        root_id = schema_id <> "#"
        TypeReferenceParser.parse(schema_root_node, nil, root_id, ["#"], "#")

      object_type?(schema_root_node) ->
        type_path = TypePath.from_string("#")
        parse_type(schema_root_node, schema_id, type_path, title)

      array_type?(schema_root_node) ->
        type_path = TypePath.from_string("#")
        parse_type(schema_root_node, schema_id, type_path, title)

      true ->
        Logger.debug "Found no valid root object"
        %{}
    end
  end

  @spec parse_type(map, URI.t, TypePath.t, String.t) :: Types.typeDictionary
  def parse_type(schema_node, parent_id, path, name) do
    Logger.debug "Parsing type with name: #{name}, " <>
      "path: #{path}, and value: #{inspect schema_node}"

    node_parser = determine_node_parser(schema_node)
    Logger.debug "node_parser: #{inspect node_parser}"

    if node_parser != nil do

      id = determine_id(schema_node, parent_id)
      parent_id = determine_parent_id(id, parent_id)
      type_path = TypePath.add_child(path, name)
      node_parser.(schema_node, parent_id, id, type_path, name)

    else
      Logger.error "Could not determine parser for node: #{inspect schema_node}"
    end
  end

  @spec determine_id(map, URI.t) :: (URI.t | nil)
  defp determine_id(schema_node, parent_id) do
    id = schema_node["id"]

    if id != nil do
      id_uri = URI.parse(id)

      if id_uri.scheme == "urn" do
        id_uri
      else
        URI.merge(parent_id, id_uri)
      end

    else
      nil
    end
  end

  @spec determine_parent_id(URI.t | nil, URI.t) :: URI.t
  defp determine_parent_id(id, parent_id) do
    if id != nil && id.scheme != "urn" do
      id
    else
      parent_id
    end
  end

  @spec determine_node_parser(map) :: (nodeParser | nil)
  defp determine_node_parser(schema_node) do

    predicate_node_type_pairs = [
      {&ref_type?/1, &TypeReferenceParser.parse/5},
      {&enum_type?/1, &EnumParser.parse/5},
      {&union_type?/1, &UnionParser.parse/5},
      {&one_of_type?/1, &OneOfParser.parse/5},
      {&object_type?/1, &ObjectParser.parse/5},
      {&array_type?/1, &ArrayParser.parse/5},
      {&primitive_type?/1, &PrimitiveParser.parse/5},
      {&definitions?/1, &DefinitionsParser.parse/5}
    ]

    predicate_node_type_pairs
    |> Enum.find({nil, nil}, fn {pred?, _node_parser} ->
      pred?.(schema_node)
    end)
    |> elem(1)
  end

  @spec supported_schema_version?(map) :: boolean
  defp supported_schema_version?(schema_root_node) do
    if Map.has_key?(schema_root_node, "$schema") do
      schema_identifier =
        schema_root_node
        |> Map.get("$schema")
        |> URI.parse

      (to_string schema_identifier) in @supported_versions
    else
      false
    end
  end

  @spec definitions?(map) :: boolean
  defp definitions?(schema_node) do
    Map.has_key?(schema_node, "definitions")
  end

  @spec primitive_type?(map) :: boolean
  defp primitive_type?(schema_node) do
    schema_node["type"] in ["null", "boolean", "string", "number", "integer"]
  end

  @spec ref_type?(map) :: boolean
  defp ref_type?(schema_node) do
    Map.has_key?(schema_node, "$ref")
  end

  @spec enum_type?(map) :: boolean
  defp enum_type?(schema_node) do
    Map.has_key?(schema_node, "enum")
  end

  @spec one_of_type?(map) :: boolean
  defp one_of_type?(schema_node) do
    Map.get(schema_node, "oneOf")
  end

  @spec union_type?(map) :: boolean
  defp union_type?(schema_node) do
    is_list(schema_node["type"])
  end

  @spec object_type?(map) :: boolean
  defp object_type?(schema_node) do
    schema_node["type"] == "object" && Map.has_key?(schema_node, "properties")
  end

  @spec array_type?(map) :: boolean
  defp array_type?(schema_node) do
    schema_node["type"] == "array" && Map.has_key?(schema_node, "items")
  end

end
