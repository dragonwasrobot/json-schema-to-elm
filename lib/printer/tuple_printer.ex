defmodule JS2E.Printer.TuplePrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing a 'tuple' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{PrinterError, PrinterResult, Utils}

  alias Utils.{
    CommonOperations,
    ElmDecoders,
    ElmEncoders,
    ElmFuzzers,
    ElmTypes,
    Indentation,
    Naming
  }

  alias Types.{SchemaDefinition, TupleType}

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "types/product_type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :product_type
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %TupleType{name: name, path: path, items: types},
        schema_def,
        schema_dict,
        module_name
      ) do
    {type_fields, errors} =
      types
      |> create_type_fields(path, schema_def, schema_dict, module_name)
      |> CommonOperations.split_ok_and_errors()

    type_name = name |> Naming.normalize_identifier(:upcase)

    %{name: type_name, fields: {:anonymous, List.flatten(type_fields)}}
    |> type_template()
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, [map]} | {:error, PrinterError.t()}]
  defp create_type_fields(types, parent, schema_def, schema_dict, module_name) do
    types
    |> Enum.map(&create_type_field(&1, parent, schema_def, schema_dict, module_name))
  end

  @spec create_type_field(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [map]} | {:error, PrinterError.t()}
  defp create_type_field(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(type_path, parent, schema_def, schema_dict),
         {:ok, type_names} <-
           ElmTypes.create_fields(
             :anonymous,
             resolved_type,
             resolved_schema,
             parent,
             schema_def,
             schema_dict,
             module_name
           ) do
      {:ok, type_names}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "decoders/product_decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :product_decoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %TupleType{name: name, path: path, items: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {decoder_clauses, errors} =
      type_paths
      |> create_decoder_clauses(path, schema_def, schema_dict, module_name)
      |> CommonOperations.split_ok_and_errors()

    normalized_name = Naming.normalize_identifier(name, :downcase)
    decoder_name = "#{normalized_name}Decoder"
    type_name = Naming.upcase_first(normalized_name)

    %{name: decoder_name, type: type_name, clauses: {:anonymous, List.flatten(decoder_clauses)}}
    |> decoder_template()
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_clauses(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_decoder_clauses(
         type_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_paths
    |> Enum.map(&create_decoder_clause(&1, parent, schema_def, schema_dict, module_name))
  end

  @spec create_decoder_clause(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_decoder_clause(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {property_type, resolved_schema_def}} <-
           Resolver.resolve_type(type_path, parent, schema_def, schema_dict),
         {:ok, clauses} <-
           ElmDecoders.create_clauses(
             :anonymous,
             property_type,
             resolved_schema_def,
             [],
             schema_def,
             schema_dict,
             module_name
           ) do
      {:ok, clauses}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/tuple_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :tuple_encoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %TupleType{name: name, path: path, items: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {encoder_properties, errors} =
      type_paths
      |> create_encoder_properties(path, schema_def, schema_dict, module_name)
      |> CommonOperations.split_ok_and_errors()

    type_name = Naming.normalize_identifier(name, :upcase)
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"

    %{name: encoder_name, type: type_name, properties: encoder_properties}
    |> encoder_template()
    |> Indentation.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_properties(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, Types.typeDefinition()} | {:error, PrinterError.t()}]
  defp create_encoder_properties(
         type_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_paths
    |> Enum.map(&Resolver.resolve_type(&1, parent, schema_def, schema_dict))
    |> Enum.map(&to_encoder_property(&1, schema_def, module_name))
  end

  @spec to_encoder_property(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) :: {:ok, Types.typeDefinition()} | {:error, PrinterError.t()}
  defp to_encoder_property({:error, error}, _sd, _md), do: {:error, error}

  defp to_encoder_property(
         {:ok, {resolved_property, resolved_schema}},
         schema_def,
         module_name
       ) do
    ElmEncoders.create_encoder_property(
      resolved_property,
      resolved_schema,
      resolved_property.name,
      [],
      schema_def,
      module_name
    )
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/tuple_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [:tuple_fuzzer])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %TupleType{name: name, path: path, items: items_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.normalize_identifier(name, :downcase)
    fuzzer_name = "#{name}Fuzzer"
    decoder_name = "#{Naming.normalize_identifier(name, :downcase)}Decoder"
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"

    {fuzzers, errors} =
      items_paths
      |> create_items_fuzzers(
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
      decoder_name: decoder_name,
      encoder_name: encoder_name,
      field_fuzzers: List.flatten(fuzzers)
    }
    |> fuzzer_template()
    |> PrinterResult.new(errors)
  end

  @spec create_items_fuzzers(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, [String.t()]} | {:error, PrinterError.t()}]
  defp create_items_fuzzers(
         items_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    items_paths
    |> Enum.map(
      &create_item_fuzzer(
        &1,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    )
  end

  @spec create_item_fuzzer(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [String.t()]} | {:error, PrinterError.t()}
  defp create_item_fuzzer(
         item_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             item_path,
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
      {:ok, fuzzer_names}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
