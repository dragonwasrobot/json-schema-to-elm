defmodule JS2E.Printer.ObjectPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer.{PrinterError, PrinterResult}

  alias JS2E.Printer.Utils.{
    CommonOperations,
    ElmDecoders,
    ElmEncoders,
    ElmFuzzers,
    ElmTypes,
    Indentation,
    Naming
  }

  alias JsonSchema.{Parser, Resolver, Types}
  alias Parser.Util, as: ParserUtil
  alias Types.{ObjectType, SchemaDefinition}

  @type property_name :: String.t()
  @type module_name :: String.t()

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "types/product_type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [:product_type])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          module_name()
        ) :: PrinterResult.t()
  def print_type(
        %ObjectType{
          name: name,
          path: path,
          properties: properties,
          required: required
        },
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)

    fields_result =
      properties
      |> Enum.map(
        &create_type_fields(
          &1,
          required,
          path,
          schema_def,
          schema_dict,
          module_name
        )
      )

    {fields, errors} =
      fields_result
      |> CommonOperations.split_ok_and_errors()

    %{name: type_name, fields: {:named, List.flatten(fields)}}
    |> type_template()
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          {property_name(), Types.typeIdentifier()},
          [property_name()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          module_name()
        ) ::
          {:ok, [ElmTypes.named_field()]}
          | {:error, PrinterError.t()}
  defp create_type_fields(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = ParserUtil.add_fragment_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, fields} <-
           ElmTypes.create_fields(
             property_name,
             resolved_type,
             resolved_schema,
             parent,
             schema_def,
             schema_dict,
             module_name
           ) do
      named_fields =
        fields
        |> Enum.map(&check_optional(&1, required))

      {:ok, named_fields}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec check_optional(ElmTypes.named_field(), [String.t()]) :: ElmTypes.named_field()
  defp check_optional(field, required) do
    if field.name in required do
      %{field | type: field.type}
    else
      %{field | type: "Maybe #{field.type}"}
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
        %ObjectType{
          name: name,
          path: path,
          properties: properties,
          required: required
        },
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    decoder_name = "#{Naming.downcase_first(type_name)}Decoder"

    {decoder_clauses, errors} =
      properties
      |> Enum.map(fn property ->
        create_decoder_clause(
          property,
          required,
          path,
          schema_def,
          schema_dict,
          module_name
        )
      end)
      |> CommonOperations.split_ok_and_errors()

    decoder_clauses =
      decoder_clauses
      |> List.flatten()
      |> Enum.map(fn clause -> check_optional_decoder(clause) end)

    %{
      name: decoder_name,
      type: type_name,
      clauses: {:named, decoder_clauses}
    }
    |> decoder_template()
    |> PrinterResult.new(errors)
  end

  @spec check_optional_decoder(map) :: map
  defp check_optional_decoder(clause) do
    if clause.option == :optional do
      %{clause | decoder_name: "(Decode.nullable #{clause.decoder_name}) Nothing"}
    else
      clause
    end
  end

  @spec create_decoder_clause(
          {String.t(), String.t()},
          [String.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) ::
          {:ok, [ElmDecoders.named_product_clause()]}
          | {:error, PrinterError.t()}
  defp create_decoder_clause(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = ParserUtil.add_fragment_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, clauses} <-
           ElmDecoders.create_clauses(
             property_name,
             resolved_type,
             resolved_schema,
             required,
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

  @encoder_location Path.join(@templates_location, "encoders/product_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :product_encoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %ObjectType{
          name: name,
          path: path,
          properties: properties,
          required: required
        },
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    encoder_name = "encode#{type_name}"
    argument_name = Naming.downcase_first(type_name)

    {encoder_properties, errors} =
      properties
      |> Enum.map(
        &create_encoder_property(
          &1,
          required,
          path,
          schema_def,
          schema_dict,
          module_name
        )
      )
      |> CommonOperations.split_ok_and_errors()

    %{
      name: encoder_name,
      type: type_name,
      argument_name: argument_name,
      properties: encoder_properties
    }
    |> encoder_template()
    |> Indentation.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_property(
          {String.t(), Types.typeIdentifier()},
          [String.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_encoder_property(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = ParserUtil.add_fragment_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, encoder_property} <-
           ElmEncoders.create_encoder_property(
             resolved_type,
             resolved_schema,
             property_name,
             required,
             schema_def,
             module_name
           ) do
      {:ok, encoder_property}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/product_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [
    :product_fuzzer
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %ObjectType{name: name, path: path, properties: properties, required: required},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.downcase_first(type_name)
    decoder_name = "#{Naming.downcase_first(type_name)}Decoder"
    encoder_name = "encode#{Naming.upcase_first(type_name)}"
    fuzzer_name = "#{Naming.downcase_first(type_name)}Fuzzer"

    {fuzzers, errors} =
      properties
      |> Enum.map(
        &create_property_fuzzer(
          &1,
          required,
          path,
          schema_def,
          schema_dict,
          module_name
        )
      )
      |> CommonOperations.split_ok_and_errors()

    %{
      name: fuzzer_name,
      type: type_name,
      argument_name: argument_name,
      decoder_name: decoder_name,
      encoder_name: encoder_name,
      fuzzers: List.flatten(fuzzers)
    }
    |> fuzzer_template()
    |> PrinterResult.new(errors)
  end

  @spec create_property_fuzzer(
          {String.t(), Types.typeIdentifier()},
          [String.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [String.t()]} | {:error, PrinterError.t()}
  defp create_property_fuzzer(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = ParserUtil.add_fragment_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, field_fuzzers} <-
           ElmFuzzers.create_fuzzer_names(
             property_name,
             resolved_type,
             resolved_schema,
             schema_def,
             schema_dict,
             module_name
           ) do
      fuzzers =
        field_fuzzers
        |> Enum.map(&check_optional_fuzzer(&1, required))

      {:ok, fuzzers}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec check_optional_fuzzer(ElmFuzzers.field_fuzzer(), [String.t()]) ::
          ElmFuzzers.field_fuzzer()
  defp check_optional_fuzzer(field_fuzzer, required) do
    if field_fuzzer.field_name in required do
      field_fuzzer
    else
      %{field_fuzzer | fuzzer_name: "(Fuzz.maybe #{field_fuzzer.fuzzer_name})"}
    end
  end
end
