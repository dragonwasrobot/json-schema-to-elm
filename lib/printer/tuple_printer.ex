defmodule JS2E.Printer.TuplePrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
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

  alias Types.{
    EnumType,
    OneOfType,
    SchemaDefinition,
    TupleType,
    UnionType
  }

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "tuple/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :type_name,
    :type_fields
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

    name
    |> Naming.normalize_identifier(:upcase)
    |> type_template(type_fields)
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, String.t()} | {:error, PrinterError.t()}]
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
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  defp create_type_field(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_path
    |> Resolver.resolve_type(parent, schema_def, schema_dict)
    |> ElmTypes.create_type_name(schema_def, module_name)
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "tuple/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :decoder_name,
    :type_name,
    :clauses
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

    decoder_name
    |> decoder_template(type_name, decoder_clauses)
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
         {:ok, decoder_name} <-
           ElmDecoders.create_decoder_name(
             {:ok, {property_type, resolved_schema_def}},
             schema_def,
             module_name
           ) do
      case property_type do
        %EnumType{} ->
          case ElmDecoders.determine_primitive_type_decoder(property_type.type) do
            {:ok, property_type_decoder} ->
              create_decoder_enum_clause(property_type_decoder, decoder_name)

            {:error, error} ->
              {:error, error}
          end

        %OneOfType{} ->
          create_decoder_union_clause(decoder_name)

        %UnionType{} ->
          create_decoder_union_clause(decoder_name)

        _ ->
          create_decoder_normal_clause(decoder_name)
      end
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_decoder_union_clause(String.t()) :: {:ok, map}
  defp create_decoder_union_clause(decoder_name) do
    {:ok, %{decoder_name: decoder_name}}
  end

  @spec create_decoder_enum_clause(String.t(), String.t()) :: {:ok, map}
  defp create_decoder_enum_clause(property_type_decoder, decoder_name) do
    {:ok, %{property_decoder: property_type_decoder, decoder_name: decoder_name}}
  end

  @spec create_decoder_normal_clause(String.t()) :: {:ok, map}
  defp create_decoder_normal_clause(decoder_name) do
    {:ok, %{decoder_name: decoder_name}}
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "tuple/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :encoder_name,
    :type_name,
    :properties
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

    encoder_name
    |> encoder_template(type_name, encoder_properties)
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
    encoder_name_result =
      ElmEncoders.create_encoder_name(
        {:ok, {resolved_property, resolved_schema}},
        schema_def,
        module_name
      )

    case encoder_name_result do
      {:ok, encoder_name} ->
        {:ok, Map.put(resolved_property, :encoder_name, encoder_name)}

      {:error, error} ->
        {:error, error}
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "tuple/fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [
    :type_name,
    :argument_name,
    :fuzzer_name,
    :decoder_name,
    :encoder_name,
    :fuzzers
  ])

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

    type_name
    |> fuzzer_template(
      argument_name,
      fuzzer_name,
      decoder_name,
      encoder_name,
      fuzzers
    )
    |> PrinterResult.new(errors)
  end

  @spec create_items_fuzzers(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, String.t()} | {:error, PrinterError.t()}]
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
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
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
         {:ok, fuzzer_name} <-
           ElmFuzzers.create_fuzzer_name(
             {:ok, {resolved_type, resolved_schema}},
             schema_def,
             module_name
           ) do
      {:ok, fuzzer_name}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
