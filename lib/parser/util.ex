defmodule JS2E.Parser.Util do
  @moduledoc ~S"""
  A module containing utility functions for JSON schema parsers.
  """

  require Logger

  alias JS2E.Parser.{
    AllOfParser,
    AnyOfParser,
    ArrayParser,
    EnumParser,
    DefinitionsParser,
    ObjectParser,
    OneOfParser,
    PrimitiveParser,
    TupleParser,
    TypeReferenceParser,
    UnionParser,
    ErrorUtil,
    ParserError,
    ParserResult
  }

  alias JS2E.{TypePath, Types}

  @type nodeParser ::
          (Types.node(), URI.t(), URI.t(), TypePath.t(), String.t() ->
             ParserResult.t())

  @doc ~S"""
  Creates a new type dictionary based on the given type definition
  and an optional ID.
  """
  @spec create_type_dict(
          Types.typeDefinition(),
          TypePath.t(),
          URI.t() | nil
        ) :: Types.typeDictionary()
  def create_type_dict(type_def, path, id) do
    string_path = path |> TypePath.to_string()

    type_dict =
      if id != nil do
        string_id =
          if type_def.name == "#" do
            "#{id}#"
          else
            "#{id}"
          end

        %{string_path => type_def, string_id => type_def}
      else
        %{string_path => type_def}
      end

    type_dict
  end

  @doc ~S"""
  Returns a list of type paths when given a type dictionary.
  """
  @spec create_types_list(Types.typeDictionary(), TypePath.t()) :: [
          TypePath.t()
        ]
  def create_types_list(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn {child_abs_path, child_type}, reference_dict ->
      child_type_path = TypePath.add_child(path, child_type.name)

      if child_type_path == TypePath.from_string(child_abs_path) do
        Map.merge(reference_dict, %{child_type.name => child_type_path})
      else
        reference_dict
      end
    end)
    |> Map.values()
  end

  @doc ~S"""
  Parse a list of JSON schema objects that have a child relation to another
  schema object with the specified `parent_id`.
  """
  @spec parse_child_types([Types.schemaNode()], URI.t(), TypePath.t()) ::
          ParserResult.t()
  def parse_child_types(child_nodes, parent_id, path)
      when is_list(child_nodes) do
    child_nodes
    |> Enum.reduce({ParserResult.new(), 0}, fn child_node, {result, idx} ->
      child_name = to_string(idx)
      child_result = parse_type(child_node, parent_id, path, child_name)
      {ParserResult.merge(result, child_result), idx + 1}
    end)
    |> elem(0)
  end

  @spec parse_type(Types.schemaNode(), URI.t(), TypePath.t(), String.t()) ::
          ParserResult.t()
  def parse_type(schema_node, parent_id, path, name) do
    definitions_result =
      if DefinitionsParser.type?(schema_node) do
        id = determine_id(schema_node, parent_id)
        parent_id = determine_parent_id(id, parent_id)
        type_path = TypePath.add_child(path, name)
        DefinitionsParser.parse(schema_node, parent_id, id, type_path, name)
      else
        ParserResult.new(%{}, [], [])
      end

    node_result =
      case determine_node_parser(schema_node, path, name) do
        nil ->
          ParserResult.new(%{}, [], [])

        node_parser ->
          id = determine_id(schema_node, parent_id)
          parent_id = determine_parent_id(id, parent_id)
          type_path = TypePath.add_child(path, name)
          node_parser.(schema_node, parent_id, id, type_path, name)
      end

    if Enum.empty?(definitions_result.type_dict) and
         Enum.empty?(node_result.type_dict) do
      unknown_type_error = ErrorUtil.unknown_node_type(path, name, schema_node)
      ParserResult.new(%{}, [], [unknown_type_error])
    else
      ParserResult.merge(definitions_result, node_result)
    end
  end

  @spec determine_node_parser(
          Types.schemaNode(),
          Types.typeIdentifier(),
          String.t()
        ) :: nodeParser | nil
  defp determine_node_parser(schema_node, identifier, name) do
    predicate_node_type_pairs = [
      {&AllOfParser.type?/1, &AllOfParser.parse/5},
      {&AnyOfParser.type?/1, &AnyOfParser.parse/5},
      {&ArrayParser.type?/1, &ArrayParser.parse/5},
      {&EnumParser.type?/1, &EnumParser.parse/5},
      {&ObjectParser.type?/1, &ObjectParser.parse/5},
      {&OneOfParser.type?/1, &OneOfParser.parse/5},
      {&PrimitiveParser.type?/1, &PrimitiveParser.parse/5},
      {&TupleParser.type?/1, &TupleParser.parse/5},
      {&TypeReferenceParser.type?/1, &TypeReferenceParser.parse/5},
      {&UnionParser.type?/1, &UnionParser.parse/5}
    ]

    node_parser =
      predicate_node_type_pairs
      |> Enum.find({nil, nil}, fn {pred?, _node_parser} ->
        pred?.(schema_node)
      end)
      |> elem(1)

    if node_parser != nil do
      node_parser
    else
      nil
    end
  end

  @doc ~S"""
  Determines the ID of a schema node based on its parent's ID and its own
  optional '$id' or id' property.
  """
  @spec determine_id(map, URI.t()) :: URI.t() | nil
  defp determine_id(%{"$id" => id}, parent_id) when is_binary(id) do
    do_determine_id(id, parent_id)
  end

  defp determine_id(%{"id" => id}, parent_id) when is_binary(id) do
    do_determine_id(id, parent_id)
  end

  defp determine_id(_schema_node, _parent_id), do: nil

  @spec do_determine_id(String.t(), URI.t()) :: URI.t()
  defp do_determine_id(id, parent_id) do
    id_uri = URI.parse(id)

    if id_uri.scheme == "urn" do
      id_uri
    else
      URI.merge(parent_id, id_uri)
    end
  end

  @spec determine_parent_id(URI.t() | nil, URI.t()) :: URI.t()
  defp determine_parent_id(id, parent_id) do
    if id != nil && id.scheme != "urn" do
      id
    else
      parent_id
    end
  end
end
