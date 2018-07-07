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

    fuzzers_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &print_fuzzer/4
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
    type_printers = [
      {AllOfType, &AllOfPrinter.print_type/4},
      {AnyOfType, &AnyOfPrinter.print_type/4},
      {ArrayType, &ArrayPrinter.print_type/4},
      {EnumType, &EnumPrinter.print_type/4},
      {ObjectType, &ObjectPrinter.print_type/4},
      {OneOfType, &OneOfPrinter.print_type/4},
      {PrimitiveType, &PrimitivePrinter.print_type/4},
      {TupleType, &TuplePrinter.print_type/4},
      {TypeReference, &TypeReferencePrinter.print_type/4},
      {UnionType, &UnionPrinter.print_type/4}
    ]

    type_printer =
      type_printers
      |> Enum.find(fn {type, _printer} -> type == type_def.__struct__ end)

    if type_printer != nil do
      {_type, printer} = type_printer
      printer.(type_def, schema_def, schema_dict, module_name)
    else
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
    decoder_printers = [
      {AllOfType, &AllOfPrinter.print_decoder/4},
      {AnyOfType, &AnyOfPrinter.print_decoder/4},
      {ArrayType, &ArrayPrinter.print_decoder/4},
      {EnumType, &EnumPrinter.print_decoder/4},
      {ObjectType, &ObjectPrinter.print_decoder/4},
      {OneOfType, &OneOfPrinter.print_decoder/4},
      {PrimitiveType, &PrimitivePrinter.print_decoder/4},
      {TupleType, &TuplePrinter.print_decoder/4},
      {TypeReference, &TypeReferencePrinter.print_decoder/4},
      {UnionType, &UnionPrinter.print_decoder/4}
    ]

    decoder_printer =
      decoder_printers
      |> Enum.find(fn {type, _printer} -> type == type_def.__struct__ end)

    if decoder_printer != nil do
      {_type, printer} = decoder_printer
      printer.(type_def, schema_def, schema_dict, module_name)
    else
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
    encoder_printers = [
      {AllOfType, &AllOfPrinter.print_encoder/4},
      {AnyOfType, &AnyOfPrinter.print_encoder/4},
      {ArrayType, &ArrayPrinter.print_encoder/4},
      {EnumType, &EnumPrinter.print_encoder/4},
      {ObjectType, &ObjectPrinter.print_encoder/4},
      {OneOfType, &OneOfPrinter.print_encoder/4},
      {PrimitiveType, &PrimitivePrinter.print_encoder/4},
      {TupleType, &TuplePrinter.print_encoder/4},
      {TypeReference, &TypeReferencePrinter.print_encoder/4},
      {UnionType, &UnionPrinter.print_encoder/4}
    ]

    encoder_printer =
      encoder_printers
      |> Enum.find(fn {type, _printer} -> type == type_def.__struct__ end)

    if encoder_printer != nil do
      {_type, printer} = encoder_printer
      printer.(type_def, schema_def, schema_dict, module_name)
    else
      struct_name = get_struct_name(type_def)
      PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(type_def, schema_def, schema_dict, module_name) do
    fuzzer_printers = [
      {AllOfType, &AllOfPrinter.print_fuzzer/4},
      {AnyOfType, &AnyOfPrinter.print_fuzzer/4},
      {ArrayType, &ArrayPrinter.print_fuzzer/4},
      {EnumType, &EnumPrinter.print_fuzzer/4},
      {ObjectType, &ObjectPrinter.print_fuzzer/4},
      {OneOfType, &OneOfPrinter.print_fuzzer/4},
      {PrimitiveType, &PrimitivePrinter.print_fuzzer/4},
      {TupleType, &TuplePrinter.print_fuzzer/4},
      {TypeReference, &TypeReferencePrinter.print_fuzzer/4},
      {UnionType, &UnionPrinter.print_fuzzer/4}
    ]

    fuzzer_printer =
      fuzzer_printers
      |> Enum.find(fn {type, _printer} -> type == type_def.__struct__ end)

    if fuzzer_printer != nil do
      {_type, printer} = fuzzer_printer
      printer.(type_def, schema_def, schema_dict, module_name)
    else
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
