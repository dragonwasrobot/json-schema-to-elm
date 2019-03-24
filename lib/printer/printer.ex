defmodule JS2E.Printer do
  @moduledoc ~S"""
  Prints an intermediate representation of a JSON schema structure into a series
  of elm decoders.
  """

  require Elixir.EEx
  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types

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

  @output_location Application.get_env(:js2e, :output_location)
  @templates_location Application.get_env(:js2e, :templates_location)

  @package_location Path.join(
                      @templates_location,
                      "project/package.json.eex"
                    )
  EEx.function_from_file(
    :defp,
    :package_template,
    @package_location
  )

  @elm_json_location Path.join(
                       @templates_location,
                       "project/elm.json.eex"
                     )
  EEx.function_from_file(
    :defp,
    :elm_json_template,
    @elm_json_location
  )

  @tool_versions_location Path.join(
                            @templates_location,
                            "project/tool_versions.eex"
                          )
  EEx.function_from_file(
    :defp,
    :tool_versions_template,
    @tool_versions_location
  )

  @utils_location Path.join(
                    @templates_location,
                    "utils/utils.elm.eex"
                  )
  EEx.function_from_file(
    :defp,
    :utils_template,
    @utils_location,
    [:prefix]
  )

  @spec print_schemas(Types.schemaDictionary(), String.t()) :: SchemaResult.t()
  def print_schemas(schema_dict, module_name) do
    init_file_dict = %{
      "./#{@output_location}/src/#{module_name}/Utils.elm" => utils_template(module_name),
      "./#{@output_location}/package.json" => package_template(),
      "./#{@output_location}/elm.json" => elm_json_template(),
      "./#{@output_location}/.tool-versions" => tool_versions_template()
    }

    schema_dict
    |> Enum.reduce(SchemaResult.new(init_file_dict), fn {_id, schema_def}, acc ->
      file_path = create_file_path(schema_def.title, module_name)
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

  @spec print_schema(SchemaDefinition.t(), Types.schemaDictionary(), String.t()) ::
          PrinterResult.t()
  def print_schema(schema_def, schema_dict, module_name) do
    type_dict = schema_def.types

    values =
      type_dict
      |> filter_aliases
      |> Enum.sort(&(&1.name < &2.name))

    preamble_result =
      schema_def
      |> PreamblePrinter.print_preamble(schema_dict, module_name)

    types_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &print_type/4
      )

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

    %{printer_result | printed_schema: printer_result.printed_schema <> "\n"}
  end

  @spec print_schemas_tests(Types.schemaDictionary(), String.t()) :: SchemaResult.t()
  def print_schemas_tests(schema_dict, module_name \\ "") do
    schema_dict
    |> Enum.reduce(SchemaResult.new(%{}), fn {_id, schema_def}, acc ->
      file_path = create_file_path(schema_def.title, module_name, true)
      result = print_schema_tests(schema_def, schema_dict, module_name)

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

  @spec print_schema_tests(
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_schema_tests(schema_def, schema_dict, module_name) do
    type_dict = schema_def.types

    values =
      type_dict
      |> filter_aliases
      |> Enum.sort(&(&1.name < &2.name))

    tests_preamble_result =
      schema_def
      |> PreamblePrinter.print_tests_preamble(schema_dict, module_name)

    fuzzers_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &print_fuzzer/4
      )

    tests_printer_result =
      tests_preamble_result
      |> PrinterResult.merge(fuzzers_result)

    tests_printer_result
    |> Map.put(:printed_schema, tests_printer_result.printed_schema <> "\n")
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
          (Types.typeDefinition(), SchemaDefinition.t(), Types.schemaDictionary(), String.t() ->
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

  @spec create_file_path(SchemaDefinition.t(), String.t()) :: String.t()
  defp create_file_path(title, module_name, is_test \\ false) do
    cond do
      is_test == true and module_name != "" ->
        "./#{@output_location}/tests/#{module_name}/#{title}Tests.elm"

      is_test == true and module_name == nil ->
        "./#{@output_location}/tests/#{title}Tests.elm"

      module_name != "" ->
        "./#{@output_location}/src/#{module_name}/#{title}.elm"

      true ->
        "./#{@output_location}/src/#{title}.elm"
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
