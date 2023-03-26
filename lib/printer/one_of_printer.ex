defmodule JS2E.Printer.OneOfPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing a 'one of' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.{Parser, Resolver, Types}
  alias Parser.ParserError
  alias Printer.{PrinterError, PrinterResult, Utils}
  alias Types.{OneOfType, SchemaDefinition}

  alias Utils.{
    CommonOperations,
    ElmDecoders,
    ElmFuzzers,
    ElmTypes,
    Indentation,
    Naming
  }

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "types/sum_type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :sum_type
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %OneOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        _module_name
      ) do
    type_name = Naming.normalize_identifier(name, :upcase)

    {type_clauses, errors} =
      types
      |> create_type_clauses(name, path, schema_def, schema_dict)
      |> CommonOperations.split_ok_and_errors()

    %{name: type_name, clauses: {:named, type_clauses}}
    |> type_template()
    |> PrinterResult.new(errors)
  end

  @spec create_type_clauses(
          [URI.t()],
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: [{:ok, ElmTypes.named_clause()} | {:error, PrinterError.t() | ParserError.t()}]
  defp create_type_clauses(type_clauses, name, parent, schema_def, schema_dict) do
    type_clauses
    |> Enum.map(&create_type_clause(&1, name, parent, schema_def, schema_dict))
  end

  @spec create_type_clause(
          URI.t(),
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: {:ok, ElmTypes.named_clause()} | {:error, PrinterError.t() | ParserError.t()}
  defp create_type_clause(type_clause_id, name, parent, schema_def, schema_dict) do
    case Resolver.resolve_type(
           type_clause_id,
           parent,
           schema_def,
           schema_dict
         ) do
      {:ok, {type_clause, _resolved_schema_def}} ->
        type_value = Naming.normalize_identifier(type_clause.name, :upcase)

        type_prefix =
          type_value
          |> String.slice(0..1)
          |> String.capitalize()

        type_name = Naming.normalize_identifier(name, :upcase)

        {:ok, %{name: "#{type_name}#{type_prefix}", type: type_value}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "decoders/sum_decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :sum_decoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %OneOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        _module_name
      ) do
    {clause_decoders, errors} =
      types
      |> create_decoder_clauses(name, path, schema_def, schema_dict)
      |> CommonOperations.split_ok_and_errors()

    normalized_name = Naming.normalize_identifier(name, :downcase)
    decoder_name = "#{normalized_name}Decoder"
    decoder_type = Naming.upcase_first(normalized_name)

    %{name: decoder_name, type: decoder_type, optional: false, clauses: {:named, clause_decoders}}
    |> decoder_template()
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_clauses(
          [URI.t()],
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: [{:ok, ElmDecoders.named_sum_clause()} | {:error, PrinterError.t()}]
  defp create_decoder_clauses(
         type_clauses,
         name,
         parent,
         schema_def,
         schema_dict
       ) do
    type_clauses
    |> Enum.map(&create_decoder_clause(&1, name, parent, schema_def, schema_dict))
  end

  @spec create_decoder_clause(
          URI.t(),
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: {:ok, ElmDecoders.named_sum_clause()} | {:error, PrinterError.t() | ParserError.t()}
  defp create_decoder_clause(
         type_clause_id,
         name,
         parent,
         schema_def,
         schema_dict
       ) do
    case Resolver.resolve_type(
           type_clause_id,
           parent,
           schema_def,
           schema_dict
         ) do
      {:ok, {type_clause, _resolved_schema_def}} ->
        type_prefix =
          type_clause.name
          |> Naming.normalize_identifier(:upcase)
          |> String.slice(0..1)
          |> String.capitalize()

        constructor_name = "#{Naming.normalize_identifier(name, :upcase)}#{type_prefix}"
        {:ok, %{decoder_name: "#{type_clause.name}Decoder", constructor_name: constructor_name}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/sum_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [:sum_encoder])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %OneOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        _module_name
      ) do
    {encoder_cases, errors} =
      types
      |> create_encoder_cases(name, path, schema_def, schema_dict)
      |> CommonOperations.split_ok_and_errors()

    type_name = Naming.normalize_identifier(name, :upcase)
    encoder_name = "encode#{type_name}"

    %{name: encoder_name, type: type_name, argument_name: name, cases: encoder_cases}
    |> encoder_template()
    |> Indentation.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_cases(
          [String.t()],
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: [{:ok, encoder_clause()} | {:error, PrinterError.t() | ParserError.t()}]
  defp create_encoder_cases(types, name, parent, schema_def, schema_dict) do
    types
    |> Enum.map(&create_encoder_clause(&1, name, parent, schema_def, schema_dict))
  end

  @type encoder_clause :: %{constructor: String.t(), encoder: String.t()}

  @spec create_encoder_clause(
          String.t(),
          String.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: {:ok, encoder_clause()} | {:error, PrinterError.t() | ParserError.t()}
  defp create_encoder_clause(type_path, name, parent, schema_def, schema_dict) do
    case Resolver.resolve_type(type_path, parent, schema_def, schema_dict) do
      {:ok, {clause_type, _resolved_schema_def}} ->
        type_name = Naming.normalize_identifier(name, :upcase)
        argument_name = Naming.normalize_identifier(clause_type.name, :downcase)
        type_value = Naming.upcase_first(argument_name)

        type_prefix =
          type_value
          |> String.slice(0..1)
          |> String.capitalize()

        {:ok,
         %{
           constructor: "#{type_name}#{type_prefix} #{argument_name}",
           encoder: "encode#{type_value} #{argument_name}"
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/sum_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [:sum_fuzzer])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %OneOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.normalize_identifier(type_name, :downcase)
    decoder_name = "#{Naming.normalize_identifier(type_name, :downcase)}Decoder"
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"
    fuzzer_name = "#{Naming.normalize_identifier(type_name, :downcase)}Fuzzer"

    {fuzzers, errors} =
      types
      |> create_fuzzer_properties(
        path,
        schema_def,
        schema_dict,
        module_name
      )
      |> CommonOperations.split_ok_and_errors()

    %{
      name: fuzzer_name,
      type: type_name,
      argument_name: argument_name,
      encoder_name: encoder_name,
      decoder_name: decoder_name,
      clause_fuzzers: List.flatten(fuzzers)
    }
    |> fuzzer_template()
    |> PrinterResult.new(errors)
  end

  @spec create_fuzzer_properties(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, ElmFuzzers.field_fuzzer()} | {:error, PrinterError.t() | ParserError.t()}]
  defp create_fuzzer_properties(
         types,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    types
    |> Enum.map(
      &create_fuzzer_property(
        &1,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    )
  end

  @spec create_fuzzer_property(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [ElmFuzzers.field_fuzzer()]} | {:error, PrinterError.t() | ParserError.t()}
  defp create_fuzzer_property(
         type,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             type,
             parent,
             schema_def,
             schema_dict
           ),
         {:ok, fuzzer_names} <-
           ElmFuzzers.create_fuzzer_names(
             resolved_type.name,
             resolved_type,
             resolved_schema,
             schema_def,
             schema_dict,
             module_name
           ) do
      {:ok, Enum.map(fuzzer_names, fn result -> result.fuzzer_name end)}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
