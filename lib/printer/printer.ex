defmodule JS2E.Printer do
  @moduledoc ~S"""
  Prints an intermediate representation of a JSON schema structure into a series
  of elm decoders.
  """

  require Logger

  alias JS2E.{Printer, Types}

  alias Printer.{
    AllOfPrinter,
    AnyOfPrinter,
    ArrayPrinter,
    EnumPrinter,
    ErrorUtil,
    ObjectPrinter,
    OneOfPrinter,
    PreamblePrinter,
    PrimitivePrinter,
    PrinterResult,
    SchemaResult,
    TuplePrinter,
    TypeReferencePrinter,
    UnionPrinter
  }

  alias Types.{
    AllOfType,
    AnyOfType,
    ArrayType,
    EnumType,
    ObjectType,
    OneOfType,
    PrimitiveType,
    SchemaDefinition,
    TupleType,
    TypeReference,
    UnionType
  }

  @spec print_schemas(Types.schemaDictionary(), String.t()) :: SchemaResult
  def print_schemas(schema_dict, module_name \\ "") do
    schema_dict
    |> Enum.reduce(SchemaResult.new(), fn {_id, schema_def}, acc ->
      file_path = create_file_path(schema_def, module_name)
      result = print_schema(schema_def, schema_dict, module_name)

      errors =
        if length(result.errors) > 0 do
          [{schema_def.file_path, result.errors}]
        else
          []
        end

      %{file_path => result.printed_schema}
      |> SchemaResult.new(errors)
      |> SchemaResult.merge(acc)
    end)
  end

  @spec create_file_path(SchemaDefinition.t(), String.t()) :: String.t()
  defp create_file_path(schema_def, module_name) do
    title = schema_def.title

    if module_name != "" do
      "./#{module_name}/#{title}.elm"
    else
      "./#{title}.elm"
    end
  end

  @spec print_schema(SchemaDefinition.t(), Types.schemaDictionary(), String.t()) ::
          PrinterResult.t()
  def print_schema(schema_def, schema_dict, module_name) do
    preamble_result =
      schema_def
      |> PreamblePrinter.print_preamble(schema_dict, module_name)

    type_dict = schema_def.types

    values =
      type_dict
      |> filter_aliases
      |> Enum.sort(&(&1.name < &2.name))

    types_result =
      merge_results(values, schema_def, schema_dict, module_name, &print_type/4)

    decoders_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &print_decoder/4
      )

    encoders_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &print_encoder/4
      )

    printer_result =
      preamble_result
      |> PrinterResult.merge(types_result)
      |> PrinterResult.merge(decoders_result)
      |> PrinterResult.merge(encoders_result)

    printer_result
    |> Map.put(:printed_schema, printer_result.printed_schema <> "\n")
  end

  @spec filter_aliases(Types.typeDictionary()) :: [Types.typeDefinition()]
  defp filter_aliases(type_dict) do
    type_dict
    |> Enum.reduce([], fn {path, value}, values ->
      if String.starts_with?(path, "#") do
        [value | values]
      else
        values
      end
    end)
  end

  @type process_fun ::
          (Types.typeDefinition(),
           SchemaDefinition.t(),
           Types.schemaDictionary(),
           String.t() ->
             PrinterResult.t())

  @spec merge_results(
          [Types.typeDefinition()],
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t(),
          process_fun
        ) :: PrinterResult.t()
  defp merge_results(values, schema_def, schema_dict, module_name, process_fun) do
    values
    |> Enum.map(&process_fun.(&1, schema_def, schema_dict, module_name))
    |> Enum.reduce(PrinterResult.new(), fn type_result, acc ->
      PrinterResult.merge(acc, type_result)
    end)
  end

  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(type_def, schema_def, schema_dict, module_name) do
    case type_def do
      %AllOfType{} ->
        AllOfPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %AnyOfType{} ->
        AnyOfPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %ArrayType{} ->
        ArrayPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %EnumType{} ->
        EnumPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %ObjectType{} ->
        ObjectPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %OneOfType{} ->
        OneOfPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %PrimitiveType{} ->
        PrimitivePrinter.print_type(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %TupleType{} ->
        TuplePrinter.print_type(type_def, schema_def, schema_dict, module_name)

      %TypeReference{} ->
        TypeReferencePrinter.print_type(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %UnionType{} ->
        UnionPrinter.print_type(type_def, schema_def, schema_dict, module_name)

      _ ->
        struct_name = get_struct_name(type_def)
        PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(type_def, schema_def, schema_dict, module_name) do
    case type_def do
      %AllOfType{} ->
        AllOfPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %AnyOfType{} ->
        AnyOfPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %ArrayType{} ->
        ArrayPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %EnumType{} ->
        EnumPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %ObjectType{} ->
        ObjectPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %OneOfType{} ->
        OneOfPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %PrimitiveType{} ->
        PrimitivePrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %TupleType{} ->
        TuplePrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %TypeReference{} ->
        TypeReferencePrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %UnionType{} ->
        UnionPrinter.print_decoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      _ ->
        struct_name = get_struct_name(type_def)
        PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(type_def, schema_def, schema_dict, module_name) do
    case type_def do
      %AllOfType{} ->
        AllOfPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %AnyOfType{} ->
        AnyOfPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %ArrayType{} ->
        ArrayPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %EnumType{} ->
        EnumPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %ObjectType{} ->
        ObjectPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %OneOfType{} ->
        OneOfPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %PrimitiveType{} ->
        PrimitivePrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %TupleType{} ->
        TuplePrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %TypeReference{} ->
        TypeReferencePrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      %UnionType{} ->
        UnionPrinter.print_encoder(
          type_def,
          schema_def,
          schema_dict,
          module_name
        )

      _ ->
        struct_name = get_struct_name(type_def)
        PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec get_struct_name(struct) :: String.t()
  defp get_struct_name(struct) do
    struct.__struct__
    |> to_string
    |> String.split(".")
    |> List.last()
  end
end
