defmodule JS2E.Printers.ObjectPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util, only: [
    create_decoder_name: 3,
    create_encoder_name: 3,
    create_type_name: 3,
    determine_primitive_type_decoder: 1,
    downcase_first: 1,
    enum_type?: 1,
    one_of_type?: 1,
    resolve_type: 3,
    split_ok_and_errors: 1,
    trim_newlines: 1,
    union_type?: 1,
    upcase_first: 1
  ]
  alias JS2E.Printers.{PrinterResult, ErrorUtil}
  alias JS2E.Types
  alias JS2E.Types.{ObjectType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "object/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :fields])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_type(%ObjectType{name: name,
                             path: _path,
                             properties: properties,
                             required: required},
    schema_def, schema_dict, module_name) do

    type_name = create_root_name(name, schema_def)
    fields_result = create_type_fields(properties, required,
      schema_def, schema_dict, module_name)

    {fields, errors} =
      fields_result
      |> split_ok_and_errors()

    type_name
    |> type_template(fields)
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_type_fields(properties, required, schema_def,
    schema_dict, module_name) do
    properties
    |> Enum.map(&(create_type_field(&1, required, schema_def,
            schema_dict, module_name)))
  end

  @spec create_type_field(
    {String.t, String.t},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: {:ok, map} | {:error, PrinterError.t}
  defp create_type_field({property_name, property_path},
    required, schema_def, schema_dict, module_name) do

    field_type_result =
      property_path
      |> resolve_type(schema_def, schema_dict)
      |> create_type_name(schema_def, module_name)
      |> check_if_maybe(property_name, required)

    case field_type_result do
      {:ok, field_type} ->
        {:ok, %{name: property_name,
                type: field_type}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec check_if_maybe(
    {:ok, String.t} | {:error, PrinterError.t},
    String.t,
    boolean) :: String.t
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
  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :type_name, :clauses])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_decoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    schema_def, schema_dict, module_name) do

    type_name = create_root_name(name, schema_def)
    decoder_name = "#{downcase_first type_name}Decoder"

    {decoder_clauses, errors} =
      properties
      |> create_decoder_properties(required, schema_def,
    schema_dict, module_name)
    |> split_ok_and_errors()

    decoder_name
    |> decoder_template(type_name, decoder_clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_properties(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_decoder_properties(properties, required,
    schema_def, schema_dict, module_name) do

    properties
    |> Enum.map(fn property ->
      create_decoder_property(property, required, schema_def,
        schema_dict, module_name)
    end)
  end

  @spec create_decoder_property(
    {String.t, String.t},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: {:ok, map} | {:error, PrinterError.t}
  defp create_decoder_property({property_name, property_path},
    required, schema_def, schema_dict, module_name) do

    with {:ok, {resolved_type, resolved_schema}} <- resolve_type(
           property_path, schema_def, schema_dict),
         {:ok, decoder_name} <- create_decoder_name(
           {:ok, {resolved_type, resolved_schema}}, schema_def, module_name)
      do

      is_required = property_name in required

      cond do
        union_type?(resolved_type) or one_of_type?(resolved_type) ->
          create_decoder_union_clause(property_name, decoder_name, is_required)

        enum_type?(resolved_type) ->

          case determine_primitive_type_decoder(resolved_type.type) do
            {:ok, property_type_decoder} ->

              create_decoder_enum_clause(property_name,
                property_type_decoder, decoder_name, is_required)

            {:error, error} ->
              {:error, error}
          end

        true ->
          create_decoder_normal_clause(property_name,
            decoder_name, is_required)
      end

      else
        {:error, error} ->
          {:error, error}
    end
  end

  @spec create_decoder_union_clause(String.t, String.t, boolean)
  :: {:ok, map}
  defp create_decoder_union_clause(property_name, decoder_name, is_required) do

    if is_required do
      {:ok, %{option: "required",
              property_name: property_name,
              decoder: decoder_name}}
    else
        {:ok, %{option: "optional",
                property_name: property_name,
                decoder: "(nullable #{decoder_name}) Nothing"}}
    end
  end

  @spec create_decoder_enum_clause(String.t, String.t, String.t, boolean)
  :: {:ok, map}
  defp create_decoder_enum_clause(property_name, property_type_decoder,
    decoder_name, is_required) do

    if is_required do
      {:ok, %{option: "required",
              property_name: property_name,
              decoder: "(#{property_type_decoder} " <>
                "|> andThen #{decoder_name})"}}
    else
        {:ok, %{option: "optional",
                property_name: property_name,
                decoder: "(#{property_type_decoder} " <>
                  "|> andThen #{decoder_name} |> maybe) Nothing"}}
    end
  end

  @spec create_decoder_normal_clause(String.t, String.t, boolean)
  :: {:ok, map}
  defp create_decoder_normal_clause(property_name, decoder_name, is_required) do

    if is_required do
      {:ok, %{option: "required",
              property_name: property_name,
              decoder: decoder_name}}
    else
        {:ok, %{option: "optional",
                property_name: property_name,
                decoder: "(nullable #{decoder_name}) Nothing"}}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "object/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :properties])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_encoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    schema_def, schema_dict, module_name) do

    type_name = create_root_name(name, schema_def)
    encoder_name = "encode#{type_name}"
    argument_name = downcase_first(type_name)

    {encoder_properties, errors} =
      properties
      |> create_encoder_properties(required, schema_def,
    schema_dict, module_name)
    |> split_ok_and_errors()

    encoder_name
    |> encoder_template(type_name, argument_name, encoder_properties)
    |> trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_properties(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_encoder_properties(properties, required,
    schema_def, schema_dict, module_name) do

    Enum.map(properties, &(create_encoder_property(&1, required,
              schema_def, schema_dict, module_name)))
  end

  @spec create_encoder_property(
    {String.t, Types.typeIdentifier},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: {:ok, map} | {:error, PrinterError.t}
  defp create_encoder_property({property_name, property_path}, required,
    schema_def, schema_dict, module_name) do

    with {:ok, {resolved_type, resolved_schema}} <- resolve_type(
           property_path, schema_def, schema_dict),
         {:ok, encoder_name} <- create_encoder_name(
           {:ok, {resolved_type, resolved_schema}}, schema_def, module_name)
      do

      is_required = property_name in required

      {:ok, %{name: property_name,
              encoder_name: encoder_name,
              required: is_required}}
      else
        {:error, error} ->
          {:error, error}
    end
  end

  @spec create_root_name(String.t, SchemaDefinition.t) :: String.t
  defp create_root_name(name, schema_def) do
    if name == "#" do
      if schema_def.title != nil do
        upcase_first schema_def.title
      else
        "Root"
      end
    else
      upcase_first name
    end
  end

end
