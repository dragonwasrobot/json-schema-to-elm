defmodule JS2E.Printer.AnyOfPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
  A printer for printing an 'any of' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{ErrorUtil, PrinterError, PrinterResult, Utils}

  alias Types.{
    AnyOfType,
    EnumType,
    ObjectType,
    OneOfType,
    SchemaDefinition,
    UnionType
  }

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

  @type_location Path.join(@templates_location, "any_of/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :type_name,
    :fields
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %AnyOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Naming.normalize_identifier(name, :upcase)

    {type_fields, errors} =
      types
      |> Enum.map(
        &create_type_field(&1, path, schema_def, schema_dict, module_name)
      )
      |> CommonOperations.split_ok_and_errors()

    type_name
    |> type_template(type_fields)
    |> PrinterResult.new(errors)
  end

  @type elm_type_field :: %{name: String.t(), type: String.t()}

  @spec create_type_field(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, elm_type_field} | {:error, PrinterError.t()}
  defp create_type_field(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    field_type_result =
      type_path
      |> Resolver.resolve_type(parent, schema_def, schema_dict)
      |> ElmTypes.create_type_name(parent, schema_def, schema_dict, module_name)

    case field_type_result do
      {:ok, field_type} ->
        field_name = field_type |> Naming.normalize_identifier(:downcase)
        field_type_name = "Maybe #{Naming.upcase_first(field_name)}"

        {:ok, %{name: field_name, type: field_type_name}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "any_of/decoder.elm.eex")
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
        %AnyOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {decoder_clauses, errors} =
      type_paths
      |> Enum.map(
        &create_decoder_property(&1, path, schema_def, schema_dict, module_name)
      )
      |> CommonOperations.split_ok_and_errors()

    normalized_name = Naming.normalize_identifier(name, :downcase)
    decoder_name = "#{normalized_name}Decoder"
    type_name = Naming.upcase_first(normalized_name)

    decoder_name
    |> decoder_template(type_name, decoder_clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_property(
          URI.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_decoder_property(
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
      property_name = property_type.name

      case property_type do
        %EnumType{} ->
          case ElmDecoders.determine_primitive_type_decoder(property_type.type) do
            {:ok, property_type_decoder} ->
              create_decoder_enum_clause(
                property_name,
                property_type_decoder,
                decoder_name
              )

            {:error, error} ->
              {:error, error}
          end

        %OneOfType{} ->
          create_decoder_union_clause(property_name, decoder_name)

        %UnionType{} ->
          create_decoder_union_clause(property_name, decoder_name)

        _ ->
          create_decoder_normal_clause(property_name, decoder_name)
      end
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_decoder_union_clause(String.t(), String.t()) :: {:ok, map}
  defp create_decoder_union_clause(property_name, decoder_name) do
    {:ok, %{property_name: property_name, decoder_name: decoder_name}}
  end

  @spec create_decoder_enum_clause(String.t(), String.t(), String.t()) ::
          {:ok, map}
  defp create_decoder_enum_clause(
         property_name,
         property_type_decoder,
         decoder_name
       ) do
    {:ok,
     %{
       property_name: property_name,
       property_decoder: property_type_decoder,
       decoder_name: decoder_name
     }}
  end

  @spec create_decoder_normal_clause(String.t(), String.t()) :: {:ok, map}
  defp create_decoder_normal_clause(property_name, decoder_name) do
    {:ok, %{property_name: property_name, decoder_name: decoder_name}}
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "any_of/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :encoder_name,
    :type_name,
    :argument_name,
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
        %AnyOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {encoder_properties, errors} =
      type_paths
      |> create_encoder_properties(path, schema_def, schema_dict, module_name)
      |> CommonOperations.split_ok_and_errors()

    argument_name = Naming.normalize_identifier(name, :downcase)
    type_name = Naming.upcase_first(argument_name)
    encoder_name = "encode#{type_name}"

    encoder_name
    |> encoder_template(type_name, argument_name, encoder_properties)
    |> Indentation.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_properties(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, [map]} | {:error, PrinterError.t()}]
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
    |> Enum.concat()
  end

  @type elm_encoder :: %{
          name: String.t(),
          encoder_name: String.t(),
          required: boolean
        }

  @spec to_encoder_property(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, elm_encoder} | {:error, PrinterError.t()}
  defp to_encoder_property({:error, error}, _sf, _md), do: {:error, error}

  defp to_encoder_property(
         {:ok, {%ObjectType{} = type_def, schema_def}},
         schema_dict,
         module_name
       ) do
    parent_name = Naming.normalize_identifier(type_def.name)
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
           {:ok, encoder_name} <-
             ElmEncoders.create_encoder_name(
               {:ok, {child_type_def, child_schema_def}},
               schema_def,
               module_name
             ) do
        updated_child_property =
          child_type_def
          |> Map.put(:required, child_name in required)
          |> Map.put(:encoder_name, encoder_name)
          |> Map.put(:parent_name, parent_name)

        {:ok, updated_child_property}
      else
        {:error, error} ->
          {:error, error}
      end
    end)
  end

  defp to_encoder_property(
         {:ok, type_def, _schema_def},
         _schema_dict,
         _module_name
       ) do
    error_msg =
      "anyOf printer expected ObjectType but found #{type_def.__struct__}"

    ErrorUtil.unexpected_type(type_def.path, error_msg)
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "any_of/fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [
    :type_name,
    :argument_name,
    :decoder_name,
    :encoder_name,
    :fuzzer_name,
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
        %AnyOfType{name: name, path: path, types: type_paths},
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
      type_paths
      |> create_fuzzer_properties(
        path,
        schema_def,
        schema_dict,
        module_name
      )
      |> CommonOperations.split_ok_and_errors()

    type_name
    |> fuzzer_template(
      argument_name,
      decoder_name,
      encoder_name,
      fuzzer_name,
      fuzzers
    )
    |> PrinterResult.new(errors)
  end

  @spec create_fuzzer_properties(
          [URI.t()],
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, String.t()} | {:error, PrinterError.t()}]
  defp create_fuzzer_properties(
         type_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_paths
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
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  defp create_fuzzer_property(
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
         {:ok, fuzzer_name} <-
           ElmFuzzers.create_fuzzer_name(
             {:ok, {resolved_type, resolved_schema}},
             schema_def,
             module_name
           ) do
      {:ok, "(Fuzz.maybe #{fuzzer_name})"}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
