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
    Naming,
    ResolveType
  }

  alias JS2E.{TypePath, Types}
  alias JS2E.Types.{ObjectType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "object/type.elm.eex")
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
      create_type_fields(
        properties,
        required,
        path,
        schema_def,
        schema_dict,
        module_name
      )

    {fields, errors} =
      fields_result
      |> CommonOperations.split_ok_and_errors()

    type_name
    |> type_template(fields)
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          Types.propertyDictionary(),
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_type_fields(
         properties,
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties
    |> Enum.map(
      &create_type_field(
        &1,
        required,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    )
  end

  @spec create_type_field(
          {String.t(), Types.typeIdentifier()},
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) ::
          {:ok, %{name: String.t(), type: String.t()}}
          | {:error, PrinterError.t()}
  defp create_type_field(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = TypePath.add_child(parent, property_name)

    field_type_result =
      property_path
      |> ResolveType.resolve_type(properties_path, schema_def, schema_dict)
      |> ElmTypes.create_type_name(schema_def, module_name)
      |> check_if_maybe(property_name, required)

    case field_type_result do
      {:ok, field_type} ->
        {:ok, %{name: property_name, type: field_type}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec check_if_maybe(
          {:ok, String.t()} | {:error, PrinterError.t()},
          String.t(),
          [String.t()]
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  defp check_if_maybe({:error, error}, _pn, _rq), do: {:error, error}

  defp check_if_maybe({:ok, field_name}, property_name, required) do
    if property_name in required do
      {:ok, field_name}
    else
      {:ok, "Maybe #{field_name}"}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "object/decoder.elm.eex")
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
      |> create_decoder_properties(
        required,
        path,
        schema_def,
        schema_dict,
        module_name
      )
      |> CommonOperations.split_ok_and_errors()

    decoder_name
    |> decoder_template(type_name, decoder_clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_properties(
          Types.propertyDictionary(),
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_decoder_properties(
         properties,
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties
    |> Enum.map(fn property ->
      create_decoder_property(
        property,
        required,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    end)
  end

  @spec create_decoder_property(
          {String.t(), String.t()},
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_decoder_property(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = TypePath.add_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           ResolveType.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, decoder_name} <-
           ElmDecoders.create_decoder_name(
             {:ok, {resolved_type, resolved_schema}},
             schema_def,
             module_name
           ) do
      is_required = property_name in required

      decoder_clause =
        create_decoder_clause(property_name, decoder_name, is_required)

      {:ok, decoder_clause}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_decoder_clause(String.t(), String.t(), boolean) :: map
  defp create_decoder_clause(property_name, decoder_name, is_required) do
    if is_required do
      %{
        option: "required",
        property_name: property_name,
        decoder: decoder_name
      }
    else
      %{
        option: "optional",
        property_name: property_name,
        decoder: "(nullable #{decoder_name}) Nothing"
      }
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "object/encoder.elm.eex")
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
      |> create_encoder_properties(
        required,
        path,
        schema_def,
        schema_dict,
        module_name
      )
      |> CommonOperations.split_ok_and_errors()

    encoder_name
    |> encoder_template(type_name, argument_name, encoder_properties)
    |> Indentation.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_properties(
          Types.propertyDictionary(),
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_encoder_properties(
         properties,
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    Enum.map(
      properties,
      &create_encoder_property(
        &1,
        required,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    )
  end

  @spec create_encoder_property(
          {String.t(), Types.typeIdentifier()},
          [String.t()],
          TypePath.t(),
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
    properties_path = TypePath.add_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           ResolveType.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, encoder_name} <-
           ElmEncoders.create_encoder_name(
             {:ok, {resolved_type, resolved_schema}},
             schema_def,
             module_name
           ) do
      is_required = property_name in required

      {:ok,
       %{name: property_name, encoder_name: encoder_name, required: is_required}}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "object/fuzzer.elm.eex")
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
    argument_name = Naming.downcase_first(type_name)
    decoder_name = "#{Naming.downcase_first(type_name)}Decoder"
    encoder_name = "encode#{Naming.upcase_first(type_name)}"
    fuzzer_name = "#{Naming.downcase_first(type_name)}Fuzzer"

    {fuzzers, errors} =
      properties
      |> create_fuzzer_properties(
        required,
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
          Types.propertyDictionary(),
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, String.t()} | {:error, PrinterError.t()}]
  defp create_fuzzer_properties(
         properties,
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties
    |> Enum.map(
      &create_fuzzer_property(
        &1,
        required,
        parent,
        schema_def,
        schema_dict,
        module_name
      )
    )
  end

  @spec create_fuzzer_property(
          {String.t(), Types.typeIdentifier()},
          [String.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  defp create_fuzzer_property(
         {property_name, property_path},
         required,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    properties_path = TypePath.add_child(parent, property_name)

    with {:ok, {resolved_type, resolved_schema}} <-
           ResolveType.resolve_type(
             property_path,
             properties_path,
             schema_def,
             schema_dict
           ),
         {:ok, fuzzer_name} <-
           ElmFuzzers.create_fuzzer_name(
             {:ok, {resolved_type, resolved_schema}},
             schema_def,
             module_name
           ) do
      is_required = property_name in required

      fuzzer_name =
        if is_required do
          fuzzer_name
        else
          "(Fuzz.maybe #{fuzzer_name})"
        end

      {:ok, fuzzer_name}
    else
      {:error, error} ->
        {:error, error}
    end
  end
end
