defmodule JS2E.Printer.AllOfPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'all of' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.{Parser, Resolver, Types}
  alias Parser.ParserError
  alias Printer.{PrinterError, PrinterResult, Utils}
  alias Types.{AllOfType, SchemaDefinition}

  alias Utils.{
    CommonOperations,
    ElmDecoders,
    ElmEncoders,
    ElmFuzzers,
    ElmTypes,
    Indentation,
    Naming
  }

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
        %AllOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        module_name
      ) do
    normalized_name = Naming.normalize_identifier(name, :downcase)
    type_name = Naming.upcase_first(normalized_name)

    {type_fields, errors} =
      types
      |> Enum.reduce({[], []}, fn type, {acc_type_fields, acc_errors} ->
        case create_type_fields(
               type,
               path,
               schema_def,
               schema_dict,
               module_name
             ) do
          {:ok, type_fields} ->
            {type_fields ++ acc_type_fields, acc_errors}

          {:error, error} ->
            {acc_type_fields, [error | acc_errors]}
        end
      end)

    type_fields = type_fields |> List.flatten() |> Enum.sort_by(& &1.name)

    %{name: type_name, fields: {:named, List.flatten(type_fields)}}
    |> type_template()
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [ElmTypes.named_clause()]} | {:error, PrinterError.t() | ParserError.t()}
  defp create_type_fields(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(type_path, parent, schema_def, schema_dict),
         {:ok, type_fields} <-
           ElmTypes.create_fields(
             :anonymous,
             resolved_type,
             resolved_schema,
             parent,
             schema_def,
             schema_dict,
             module_name
           ) do
      type_fields =
        type_fields
        |> Enum.map(&check_optional(&1, [resolved_type.name | resolved_type.required]))

      {:ok, type_fields}
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
        %AllOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {decoder_clauses, errors} =
      type_paths
      |> Enum.reduce({[], []}, fn type_path, {acc_clauses, acc_errors} ->
        case create_decoder_properties(
               type_path,
               path,
               schema_def,
               schema_dict,
               module_name
             ) do
          {:ok, decoder_clauses} ->
            {decoder_clauses ++ acc_clauses, acc_errors}

          {:error, error} ->
            {acc_clauses, [error | acc_errors]}
        end
      end)

    normalized_name = Naming.normalize_identifier(name, :downcase)
    decoder_name = "#{normalized_name}Decoder"
    type_name = Naming.upcase_first(normalized_name)

    decoder_clauses = decoder_clauses |> List.flatten() |> Enum.sort_by(& &1.property_name)

    %{
      name: decoder_name,
      type: type_name,
      clauses: {:named, decoder_clauses}
    }
    |> decoder_template()
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_properties(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) ::
          {:ok, [ElmDecoders.named_product_clause()]}
          | {:error, PrinterError.t() | ParserError.t()}
  defp create_decoder_properties(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema_def}} <-
           Resolver.resolve_type(type_path, parent, schema_def, schema_dict),
         {:ok, decoder_clauses} <-
           ElmDecoders.create_clauses(
             :anonymous,
             resolved_type,
             resolved_schema_def,
             [resolved_type.name],
             schema_def,
             schema_dict,
             module_name
           ) do
      decoder_clauses =
        decoder_clauses
        |> Enum.map(fn clause ->
          if clause.property_name == resolved_type.name do
            %{clause | option: :custom}
          else
            option =
              if clause.property_name in resolved_type.required do
                :required
              else
                :optional
              end

            %{clause | option: option}
          end
        end)

      {:ok, decoder_clauses}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/product_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [:product_encoder])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %AllOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {encoder_properties, errors} =
      type_paths
      |> Enum.map(&create_encoder_property(&1, path, schema_def, schema_dict, module_name))
      |> List.flatten()
      |> CommonOperations.split_ok_and_errors()

    argument_name = Naming.normalize_identifier(name, :downcase)
    type_name = Naming.normalize_identifier(argument_name, :upcase)
    encoder_name = "encode#{type_name}"

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
          Types.typeIdentifier(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, ElmEncoders.product_encoder()} | {:error, PrinterError.t() | ParserError.t()}
  defp create_encoder_property(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    case Resolver.resolve_type(type_path, parent, schema_def, schema_dict) do
      {:ok, {resolved_type, resolved_schema}} ->
        to_encoder_property(resolved_type, resolved_schema, schema_dict, module_name)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec to_encoder_property(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, ElmEncoders.product_encoder()} | {:error, PrinterError.t()}]
  defp to_encoder_property(
         type_def,
         schema_def,
         schema_dict,
         module_name
       ) do
    required = type_def.required

    type_def.properties
    |> Enum.map(fn {child_name, child_path} ->
      with {:ok, {child_type_def, child_schema_def}} <-
             Resolver.resolve_type(
               child_path,
               type_def.path,
               schema_def,
               schema_dict
             ),
           {:ok, property_encoder} <-
             ElmEncoders.create_encoder_property(
               child_type_def,
               child_schema_def,
               child_name,
               [],
               schema_def,
               module_name
             ) do
        property_encoder =
          if type_def.name != :anonymous do
            %{
              property_encoder
              | required: child_name in required,
                location: type_def.name <> "." <> property_encoder.name
            }
          else
            %{property_encoder | required: child_name in required}
          end

        {:ok, property_encoder}
      else
        {:error, error} ->
          {:error, error}
      end
    end)
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/product_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [:product_fuzzer])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %AllOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.normalize_identifier(type_name, :downcase)
    decoder_name = "#{Naming.normalize_identifier(type_name, :downcase)}Decoder"
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"
    fuzzer_name = "#{Naming.normalize_identifier(type_name, :downcase)}Fuzzer"

    {field_fuzzers, errors} =
      type_paths
      |> Enum.map(
        &create_property_fuzzer(
          &1,
          path,
          schema_def,
          schema_dict,
          module_name
        )
      )
      |> CommonOperations.split_ok_and_errors()

    field_fuzzers = field_fuzzers |> List.flatten() |> Enum.sort_by(& &1.field_name)

    %{
      name: fuzzer_name,
      type: type_name,
      argument_name: argument_name,
      decoder_name: decoder_name,
      encoder_name: encoder_name,
      fuzzers: field_fuzzers
    }
    |> fuzzer_template()
    |> PrinterResult.new(errors)
  end

  @spec create_property_fuzzer(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [ElmFuzzers.field_fuzzer()]} | {:error, PrinterError.t()}
  defp create_property_fuzzer(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {resolved_type, resolved_schema}} <-
           Resolver.resolve_type(
             type_path,
             parent,
             schema_def,
             schema_dict
           ),
         {:ok, fuzzers} <-
           ElmFuzzers.create_fuzzer_names(
             resolved_type.name,
             resolved_type,
             resolved_schema,
             schema_def,
             schema_dict,
             module_name
           ) do
      {:ok, fuzzers}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
