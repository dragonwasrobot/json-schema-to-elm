defmodule JS2E.Printer do
  @moduledoc ~S"""
  Prints an intermediate representation of a JSON schema structure into a series
  of elm decoders.
  """

  require Logger
  import JS2E.Printers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Printers.{AllOfPrinter, AnyOfPrinter, ArrayPrinter,
                       EnumPrinter, ObjectPrinter, OneOfPrinter,
                       PreamblePrinter, PrimitivePrinter, TuplePrinter,
                       TypeReferencePrinter, UnionPrinter}
  alias JS2E.Types.{PrimitiveType, TypeReference, SchemaDefinition}

  @spec print_schemas(Types.schemaDictionary)
  :: {:ok, Types.fileDictionary}
  def print_schemas(schema_dict) do

    create_file_path = fn (schema_def) ->
      title = schema_def.title
      module_name = schema_def.module

      if module_name != "" do
        "./#{module_name}/#{title}.elm"
      else
        "./#{title}.elm"
      end
    end

    result = schema_dict
    |> Enum.reduce(%{}, fn ({_id, schema_def}, acc) ->
      file_path = create_file_path.(schema_def)
      output_file = print_schema(schema_def, schema_dict)
      acc |> Map.put(file_path, output_file)
    end)

    {:ok, result}
  end

  @spec print_schema(SchemaDefinition.t, Types.schemaDictionary) :: String.t
  def print_schema(schema_def, schema_dict) do

    preamble =
      schema_def
      |> PreamblePrinter.print_preamble(schema_dict)

    type_dict = schema_def.types

    values =
      type_dict
      |> filter_aliases
      |> Enum.sort(&(&1.name < &2.name))

    types =
      values
      |> Enum.map_join("\n\n", &(print_type(&1, schema_def, schema_dict)))

    decoders =
      values
      |> Enum.map_join("\n\n", &(print_decoder(&1, schema_def, schema_dict)))

    encoders =
      values
      |> Enum.map_join("\n\n", &(print_encoder(&1, schema_def, schema_dict)))

    """
    #{String.trim(preamble)}
    \n
    #{String.trim(types)}
    \n
    #{String.trim(decoders)}
    \n
    #{String.trim(encoders)}
    """
  end

  @spec filter_aliases(Types.typeDictionary) :: Types.typeDictionary
  defp filter_aliases(type_dict) do
    type_dict
    |> Enum.reduce([], fn ({path, value}, values) ->
      if String.starts_with?(path, "#") do
        [value | values]
      else
        values
      end
    end)
  end

  @spec print_type(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_type(type_def, schema_def, schema_dict) do

    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_type/3,
      "AnyOfType" => &AnyOfPrinter.print_type/3,
      "ArrayType" => &ArrayPrinter.print_type/3,
      "EnumType" => &EnumPrinter.print_type/3,
      "ObjectType" => &ObjectPrinter.print_type/3,
      "OneOfType" => &OneOfPrinter.print_type/3,
      "PrimitiveType" => &PrimitivePrinter.print_type/3,
      "TupleType" => &TuplePrinter.print_type/3,
      "TypeReference" => &TypeReferencePrinter.print_type/3,
      "UnionType" => &UnionPrinter.print_type/3
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      type_to_printer_dict[struct_name].(type_def, schema_def, schema_dict)
    else
      Logger.error "Error(print_type) unknown type: #{inspect struct_name}"
    end
  end

  @spec print_decoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(type_def, schema_def, schema_dict) do

    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_decoder/3,
      "AnyOfType" => &AnyOfPrinter.print_decoder/3,
      "ArrayType" => &ArrayPrinter.print_decoder/3,
      "EnumType" => &EnumPrinter.print_decoder/3,
      "ObjectType" => &ObjectPrinter.print_decoder/3,
      "OneOfType" => &OneOfPrinter.print_decoder/3,
      "PrimitiveType" => &PrimitivePrinter.print_decoder/3,
      "TupleType" => &TuplePrinter.print_decoder/3,
      "TypeReference" => &TypeReferencePrinter.print_decoder/3,
      "UnionType" => &UnionPrinter.print_decoder/3
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      printer = type_to_printer_dict[struct_name]
      printer.(type_def, schema_def, schema_dict)
    else
      Logger.error "Error(print_decoder) unknown type: #{inspect struct_name}"
    end
  end

  @spec print_encoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(type_def, schema_def, schema_dict) do

    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_encoder/3,
      "AnyOfType" => &AnyOfPrinter.print_encoder/3,
      "ArrayType" => &ArrayPrinter.print_encoder/3,
      "EnumType" => &EnumPrinter.print_encoder/3,
      "ObjectType" => &ObjectPrinter.print_encoder/3,
      "OneOfType" => &OneOfPrinter.print_encoder/3,
      "PrimitiveType" => &PrimitivePrinter.print_encoder/3,
      "TupleType" => &TuplePrinter.print_encoder/3,
      "TypeReference" => &TypeReferencePrinter.print_encoder/3,
      "UnionType" => &UnionPrinter.print_encoder/3
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      printer = type_to_printer_dict[struct_name]
      printer.(type_def, schema_def, schema_dict)
    else
      Logger.error "Error(print_encoder) unknown type: #{inspect struct_name}"
    end
  end

  @spec resolve_type!(
    Types.typeIdentifier,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: {Types.typeDefinition, SchemaDefinition.t}
  def resolve_type!(identifier, schema_def, schema_dict) do
    Logger.debug "Looking up '#{inspect identifier}' in #{inspect schema_def}"

    {resolved_type, resolved_schema_def} = (cond do

      identifier in ["string", "number", "integer", "boolean"] ->
        resolve_primitive_identifier(identifier, schema_def)

      TypePath.type_path?(identifier) ->
        resolve_type_path_identifier(identifier, schema_def)

      URI.parse(identifier).scheme != nil ->
        resolve_uri_identifier(identifier, schema_dict)

      true ->
        raise "Could not resolve identifier: '#{identifier}'"
    end)

    Logger.debug("Resolved type: #{inspect resolved_type}")
    Logger.debug("Resolved schema: #{inspect resolved_schema_def}")

    if resolved_type.__struct__ == TypeReference do
      resolve_type!(resolved_type.path, resolved_schema_def, schema_dict)
    else
      {resolved_type, resolved_schema_def}
    end
  end

  @spec resolve_primitive_identifier(String.t, SchemaDefinition.t)
  :: {Types.typeDefinition, SchemaDefinition.t}
  defp resolve_primitive_identifier(identifier, schema_def) do
    primitive_type = PrimitiveType.new(identifier, identifier, identifier)
    {primitive_type, schema_def}
  end

  @spec resolve_type_path_identifier(TypePath.t, SchemaDefinition.t)
  :: {Types.typeDefinition, SchemaDefinition.t}
  defp resolve_type_path_identifier(identifier, schema_def) do
    type_dict = schema_def.types
    resolved_type = type_dict[TypePath.to_string(identifier)]
    {resolved_type, schema_def}
  end

  @spec resolve_uri_identifier(String.t, Types.schemaDictionary)
  :: {Types.typeDefinition, SchemaDefinition.t}
  defp resolve_uri_identifier(identifier, schema_dict) do

    determine_schema_id = fn identifier ->
      identifier |> URI.parse |> URI.merge("#") |> to_string
    end

    schema_id = determine_schema_id.(identifier)
    schema_def = schema_dict[schema_id]
    type_dict = schema_def.types

    resolved_type = if to_string(identifier) == schema_id do
      type_dict["#"]
    else
      type_dict[to_string(identifier)]
    end

    {resolved_type, schema_def}
  end

end
