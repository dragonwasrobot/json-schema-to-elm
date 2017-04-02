defmodule JS2E.Printers.PreamblePrinter do
  @moduledoc """
  A printer for printing a 'preamble' for a module.
  """

  require Logger
  alias JS2E.{Printer, Types}
  alias JS2E.Printers.Util
  alias JS2E.Types.{TypeReference, SchemaDefinition}

  @spec print_preamble(
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t) :: String.t
  def print_preamble(%SchemaDefinition{id: schema_id,
                                       title: title,
                                       description: description,
                                       types: type_dict},
    schema_dict, module_name \\ "") do

    prefix = create_prefix(module_name)
    other_imports =
      type_dict
      |> print_other_imports(schema_id, prefix, schema_dict)

    """
    module #{prefix}#{title} exposing (..)

    -- #{description}

    import Json.Decode as Decode
        exposing
            ( float
            , int
            , string
            , list
            , succeed
            , fail
            , map
            , maybe
            , field
            , at
            , andThen
            , oneOf
            , nullable
            , Decoder
            )
    import Json.Decode.Pipeline
        exposing
            ( decode
            , required
            , optional
            , custom
            )
    import Json.Encode as Encode
        exposing
            ( Value
            , float
            , int
            , string
            , list
            , object
            )
    #{other_imports}
    """
  end

  @spec create_prefix(String.t) :: String.t
  defp create_prefix(module_name) do
    if module_name != "" do
      module_name <> "."
    else
      ""
    end
  end

  @spec print_other_imports(
    Types.typeDictionary,
    URI.t,
    String.t,
    Types.schemaDictionary
  ) :: String.t
  defp print_other_imports(type_dict, schema_id, prefix, schema_dict) do
    type_dict
    |> get_type_references
    |> create_dependency_map(schema_id, schema_dict)
    |> print_dependencies(prefix, type_dict, schema_dict)
  end

  @spec get_type_references(Types.typeDictionary) :: [TypeReference.t]
  defp get_type_references(type_dict) do
    type_dict
    |> Enum.reduce([], fn ({_path, type}, types) ->
      if Util.get_string_name(type) == "TypeReference" do
        [type | types]
      else
        types
      end
    end)
  end

  @spec create_dependency_map(
    [TypeReference.t],
    URI.t,
    Types.schemaDictionary
  ) :: %{required(String.t) => TypeReference.t}
  defp create_dependency_map(type_refs, schema_id, schema_dict) do

    type_refs
    |> Enum.reduce(%{}, fn (type_ref, dependency_map) ->
      type_ref
      |> resolve_dependency(dependency_map, schema_id, schema_dict)
    end)
  end

  @spec resolve_dependency(
    TypeReference.t,
    %{required(String.t) => [TypeReference.t]},
    URI.t,
    Types.schemaDictionary
  ) :: %{required(String.t) => [TypeReference.t]}
  defp resolve_dependency(type_ref, dependency_map, schema_uri, schema_dict) do
    type_ref_uri = URI.parse(type_ref.path)

    cond do
      has_relative_path?(type_ref_uri) ->
        dependency_map

      has_same_absolute_path?(type_ref_uri, schema_uri) ->
        dependency_map

      has_different_absolute_path?(type_ref_uri, schema_uri) ->

        type_ref_schema_uri =
          type_ref_uri
          |> URI.merge("#")
          |> to_string

        type_ref_schema_def = schema_dict[type_ref_schema_uri]

        type_refs = if Map.has_key?(dependency_map, type_ref_schema_def.id) do
          [type_ref |  dependency_map[type_ref_schema_def.id]]
        else
          [type_ref]
        end

        dependency_map
        |> Map.put(type_ref_schema_def.id, type_refs)
    end
  end

  @spec print_dependencies(
    %{required(String.t) => TypeReference.t},
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_dependencies(dependency_map, prefix, type_dict, schema_dict) do
    indent = Util.indent()

    dependency_map
    |> Enum.reduce("", fn({schema_id, type_refs}, string_result) ->

      type_ref_schema = schema_dict[to_string(schema_id)]
      type_ref_schema_title = type_ref_schema.title

      type_ref_dependencies =
        type_refs
        |> Enum.sort(&(&2.name < &1.name))
        |> Enum.map_join("\n#{indent}#{indent}, ", fn type_ref ->
        print_import(type_ref, type_dict, schema_dict)
      end)

      string_result <>
    """
    import #{prefix}#{type_ref_schema_title}
        exposing
            ( #{type_ref_dependencies}
            )
    """
    end)
  end

  @spec print_import(
    TypeReference.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_import(type_ref, type_dict, schema_dict) do
    indent = Util.indent()

    type_path = type_ref.path
    resolved_type = type_path |> Printer.resolve_type(type_dict, schema_dict)
    resolved_type_name = Util.upcase_first resolved_type.name
    resolved_decoder_name = "#{resolved_type.name}Decoder"
    resolved_encoder_name = "encode#{resolved_type_name}"

    "#{resolved_type_name}" <>
      "\n#{indent}#{indent}, #{resolved_decoder_name}" <>
      "\n#{indent}#{indent}, #{resolved_encoder_name}"
  end

  @spec has_relative_path?(URI.t) :: boolean
  defp has_relative_path?(type_uri) do
    type_uri.scheme == nil
  end

  @spec has_same_absolute_path?(URI.t, URI.t) :: boolean
  defp has_same_absolute_path?(type_uri, schema_uri) do
    type_uri.host == schema_uri.host and
    type_uri.path == schema_uri.path
  end

  @spec has_different_absolute_path?(URI.t, URI.t) :: boolean
  defp has_different_absolute_path?(type_uri, schema_uri) do
    type_uri.host == schema_uri.host and
    type_uri.path != schema_uri.path
  end

end
