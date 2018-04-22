defmodule JS2E.Printer do
  @moduledoc ~S"""
  Prints an intermediate representation of a JSON schema structure into a series
  of elm decoders.
  """

  require Logger
  alias JS2E.Printer.{Util, PreamblePrinter, PrinterResult, SchemaResult}
  alias JS2E.Types
  alias JS2E.Types.SchemaDefinition

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
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &Util.print_type/4
      )

    decoders_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &Util.print_decoder/4
      )

    encoders_result =
      merge_results(
        values,
        schema_def,
        schema_dict,
        module_name,
        &Util.print_encoder/4
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
end
