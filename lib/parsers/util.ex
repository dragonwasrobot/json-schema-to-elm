defmodule JS2E.Parsers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema parsers.
  """

  require Logger
  alias JS2E.Parsers.{AllOfParser, AnyOfParser, ArrayParser, EnumParser,
                      DefinitionsParser, ObjectParser, OneOfParser,
                      PrimitiveParser, TupleParser, TypeReferenceParser,
                      UnionParser}
  alias JS2E.{TypePath, Types}

  @type nodeParser :: (
    map, URI.t, URI.t, TypePath.t, String.t -> Types.typeDictionary
  )

  @doc ~S"""
  Creates a new type dictionary based on the given type definition
  and an optional ID.
  """
  @spec create_type_dict(
    Types.typeDefinition,
    TypePath.t,
    URI.t | nil
  ) :: Types.typeDictionary
  def create_type_dict(type_def, path, id) do

    string_path = path |> TypePath.to_string

    if id != nil do
      string_id = if type_def.name == "#" do "#{id}#" else "#{id}" end

      %{string_path => type_def,
        string_id => type_def}
    else
      %{string_path => type_def}
    end
  end

  @doc ~S"""
  Creates a type dictionary based on a list of JSON schema objects.
  """
  @spec create_descendants_type_dict([map], URI.t, TypePath.t)
  :: Types.typeDictionary
  def create_descendants_type_dict(types, parent_id, path)
  when is_list(types) do
    types
    |> Enum.reduce({%{}, 0}, fn(child_node, {type_dict, idx}) ->

      child_name = to_string idx
      child_types = parse_type(child_node, parent_id, path, child_name)

      {Map.merge(type_dict, child_types), idx + 1}
    end)
    |> elem(0)
  end

  @doc ~S"""
  Returns a list of type paths when given a type dictionary.
  """
  @spec create_types_list(Types.typeDictionary, TypePath.t) :: [TypePath.t]
  def create_types_list(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn({child_abs_path, child_type}, reference_dict) ->

      child_type_path = TypePath.add_child(path, child_type.name)

      if child_type_path == TypePath.from_string(child_abs_path) do
        Map.merge(reference_dict, %{child_type.name => child_type_path})
      else
        reference_dict
      end

    end)
    |> Map.values()
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

  @spec determine_node_parser(map) :: (nodeParser | nil)
  defp determine_node_parser(schema_node) do

    predicate_node_type_pairs = [
      {&TypeReferenceParser.type?/1, &TypeReferenceParser.parse/5},
      {&EnumParser.type?/1, &EnumParser.parse/5},
      {&UnionParser.type?/1, &UnionParser.parse/5},
      {&AllOfParser.type?/1, &AllOfParser.parse/5},
      {&AnyOfParser.type?/1, &AnyOfParser.parse/5},
      {&OneOfParser.type?/1, &OneOfParser.parse/5},
      {&ObjectParser.type?/1, &ObjectParser.parse/5},
      {&ArrayParser.type?/1, &ArrayParser.parse/5},
      {&TupleParser.type?/1, &TupleParser.parse/5},
      {&PrimitiveParser.type?/1, &PrimitiveParser.parse/5},
      {&DefinitionsParser.type?/1, &DefinitionsParser.parse/5}
    ]

    predicate_node_type_pairs
    |> Enum.find({nil, nil}, fn {pred?, _node_parser} ->
      pred?.(schema_node)
    end)
    |> elem(1)
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

end
