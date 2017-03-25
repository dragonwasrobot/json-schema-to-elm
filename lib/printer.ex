defmodule JS2E.Printer do
  @moduledoc ~S"""
  Prints an intermediate representation of a JSON schema structure into a series
  of elm decoders.
  """

  require Logger
  alias JS2E.{TypePath, Types}
  alias JS2E.Printers.{ArrayPrinter, EnumPrinter, ObjectPrinter,
                       OneOfPrinter, PrimitivePrinter, UnionPrinter,
                       PreamblePrinter, TypeReferencePrinter, Util}
  alias JS2E.Types.{PrimitiveType, TypeReference, SchemaDefinition}

  @primitive_types ["boolean", "null", "string", "number", "integer"]

  @spec print_schemas(Types.schemaDictionary, String.t) :: Types.fileDictionary
  def print_schemas(schema_dict, module_name \\ "") do

    create_file_path = fn (module_name, schema_def) ->
      title = schema_def.title

      if module_name != "" do
        "./#{module_name}/Decoders/#{title}.elm"
      else
        "./Decoders/#{title}.elm"
      end
    end

    schema_dict
    |> Enum.reduce(%{}, fn ({_id, schema_def}, acc) ->
      file_path = create_file_path.(module_name, schema_def)
      output_file = print_schema(schema_def, schema_dict, module_name)
      acc |> Map.put(file_path, output_file)
    end)
  end

  @spec print_schema(
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: String.t
  def print_schema(%SchemaDefinition{id: _id,
                                     title: _title,
                                     description: _description,
                                     types: type_dict} = schema_def,
    schema_dict, module_name \\ "") do

    preamble =
      schema_def
      |> PreamblePrinter.print_preamble(schema_dict, module_name)

    values = type_dict
    |> filter_aliases
    |> Enum.sort(&(&1.name < &2.name))

    types = values
    |> Enum.map_join("\n\n", &(print_type(&1, type_dict, schema_dict)))

    decoders = values
    |> Enum.map_join("\n\n", &(print_decoder(&1, type_dict, schema_dict)))

    """
    #{String.trim(preamble)}
    \n
    #{String.trim(types)}
    \n
    #{String.trim(decoders)}
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
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(type_def, type_dict, schema_dict) do

    type_to_printer_dict = %{
      "ArrayType" => &ArrayPrinter.print_type/3,
      "EnumType" => &EnumPrinter.print_type/3,
      "ObjectType" => &ObjectPrinter.print_type/3,
      "PrimitiveType" => &PrimitivePrinter.print_type/3,
      "OneOfType" => &OneOfPrinter.print_type/3,
      "UnionType" => &UnionPrinter.print_type/3,
      "TypeReference" => &TypeReferencePrinter.print_type/3
    }

    struct_name = Util.get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      type_to_printer_dict[struct_name].(type_def, type_dict, schema_dict)
    else
      Logger.error "Error(print_type) unknown type: #{inspect struct_name}"
    end
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(type_def, type_dict, schema_dict) do

    type_to_printer_dict = %{
      "ArrayType" => &ArrayPrinter.print_decoder/3,
      "EnumType" => &EnumPrinter.print_decoder/3,
      "ObjectType" => &ObjectPrinter.print_decoder/3,
      "PrimitiveType" => &PrimitivePrinter.print_decoder/3,
      "OneOfType" => &OneOfPrinter.print_decoder/3,
      "UnionType" => &UnionPrinter.print_decoder/3,
      "TypeReference" => &TypeReferencePrinter.print_decoder/3
    }

    struct_name = Util.get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      printer = type_to_printer_dict[struct_name]
      printer.(type_def, type_dict, schema_dict)
    else
      Logger.error "Error(print_decoder) unknown type: #{inspect struct_name}"
    end
  end

  @spec determine_schema_id(URI.t) :: String.t
  defp determine_schema_id(identifier) do
    identifier
    |> URI.parse
    |> URI.merge("#")
    |> to_string
  end

  @spec resolve_type(
    Types.typeIdentifier,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: Types.typeDefinition
  def resolve_type(identifier, type_dict, schema_dict) do
    Logger.debug "Looking up '#{identifier}' in #{inspect type_dict}"

    type = cond do
      identifier in @primitive_types ->
        %PrimitiveType{name: identifier,
                       path: identifier,
                       type: identifier}

      TypePath.type_path?(identifier) ->
        type_dict[TypePath.to_string(identifier)]

      URI.parse(identifier).scheme != nil ->
        schema_id = determine_schema_id(identifier)
        schema = schema_dict[to_string(schema_id)]
        schema_type_dict = schema.types
        schema_type_dict[to_string(identifier)]

      true ->
        Logger.error("Could not resolve '#{identifier}'")
        nil
    end

    Logger.debug("Found type: #{inspect type}")

    if type.__struct__ == TypeReference do
      resolve_type(type.path, type_dict, schema_dict)
    else
      type
    end

  end

end
