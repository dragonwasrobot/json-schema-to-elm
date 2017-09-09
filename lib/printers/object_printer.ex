defmodule JS2E.Printers.ObjectPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @type_location Path.join(@templates_location, "object/type.elm.eex")
  @decoder_location Path.join(@templates_location, "object/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "object/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.{Printer, Types}
  alias JS2E.Types.{ObjectType, SchemaDefinition}

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :fields])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :type_name, :clauses])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :properties])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_type(%ObjectType{name: name,
                             path: _path,
                             properties: properties,
                             required: required}, schema_def, schema_dict) do

    type_name = (if name == "#" do
      if schema_def.title != nil do
        upcase_first schema_def.title
      else
        "Root"
      end
    else
      upcase_first name
    end)

    fields = create_type_fields(properties, required, schema_def, schema_dict)

    type_template(type_name, fields)
  end

  @spec create_type_fields(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_type_fields(properties, required, schema_def, schema_dict) do

    properties
    |> Enum.map(&(create_type_field(&1, required, schema_def, schema_dict)))
  end

  @spec create_type_field(
    {String.t, String.t},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_type_field({property_name, property_path},
    required, schema_def, schema_dict) do

    check_if_maybe = fn (field_name, property_name, required) ->
      if property_name in required do
        field_name
      else
        "Maybe #{field_name}"
      end
    end

    field_type =
      property_path
      |> Printer.resolve_type!(schema_def, schema_dict)
      |> create_type_name(schema_def)
      |> check_if_maybe.(property_name, required)

    %{name: property_name,
      type: field_type}
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_decoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    schema_def, schema_dict) do

    type_name = (if name == "#" do
      if schema_def.title != nil do
        upcase_first schema_def.title
      else
        "Root"
      end
    else
      upcase_first name
    end)
    decoder_name = "#{downcase_first type_name}Decoder"

    clauses = create_decoder_properties(
      properties, required, schema_def, schema_dict)

    decoder_template(decoder_name, type_name, clauses)
  end

  @spec create_decoder_properties(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_decoder_properties(properties, required,
    schema_def, schema_dict) do

    properties
    |> Enum.map(fn property ->
      create_decoder_property(property, required, schema_def, schema_dict)
    end)
  end

  @spec create_decoder_property(
    {String.t, String.t},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_decoder_property({property_name, property_path},
    required, schema_def, schema_dict) do

    {property_type, resolved_schema_def} =
      property_path
      |> Printer.resolve_type!(schema_def, schema_dict)

    decoder_name = create_decoder_name(
      {property_type, resolved_schema_def}, schema_def)

    is_required = property_name in required

    cond do
      union_type?(property_type) || one_of_type?(property_type) ->
        create_decoder_union_clause(property_name, decoder_name, is_required)

      enum_type?(property_type) ->
        property_type_decoder =
          property_type.type
          |> determine_primitive_type_decoder!()

        create_decoder_enum_clause(property_name, property_type_decoder,
          decoder_name, is_required)

      true ->
        create_decoder_normal_clause(property_name, decoder_name, is_required)
    end
  end

  defp create_decoder_union_clause(property_name, decoder_name, is_required) do
    if is_required do
      %{option: "required",
        property_name: property_name,
        decoder: decoder_name}
    else
        %{option: "optional",
          property_name: property_name,
          decoder: "(nullable #{decoder_name}) Nothing"}
    end
  end

  defp create_decoder_enum_clause(property_name, property_type_decoder,
    decoder_name, is_required) do
    if is_required do
      %{option: "required",
        property_name: property_name,
        decoder: "(#{property_type_decoder} " <>
          "|> andThen #{decoder_name})"}
    else
        %{option: "optional",
          property_name: property_name,
          decoder: "(#{property_type_decoder} " <>
            "|> andThen #{decoder_name} |> maybe) Nothing"}
    end
  end

  defp create_decoder_normal_clause(property_name, decoder_name, is_required) do
    if is_required do
      %{option: "required",
        property_name: property_name,
        decoder: decoder_name}
    else
        %{option: "optional",
          property_name: property_name,
          decoder: "(nullable #{decoder_name}) Nothing"}
    end
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_encoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    schema_def, schema_dict) do

    type_name = (if name == "#" do
      if schema_def.title != nil do
        upcase_first schema_def.title
      else
        "Root"
      end
    else
      upcase_first name
    end)

    encoder_name = "encode#{type_name}"

    argument_name = downcase_first type_name

    properties = create_encoder_properties(properties, required,
      schema_def, schema_dict)

    template = encoder_template(encoder_name, type_name,
      argument_name, properties)
    trim_newlines(template)
  end

  @spec create_encoder_properties(
    Types.propertyDictionary,
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_encoder_properties(properties, required,
    schema_def, schema_dict) do

    properties
    |> Enum.map(fn property ->
      create_encoder_property(property, required, schema_def, schema_dict)
    end)
  end

  @spec create_encoder_property(
    {String.t, String.t},
    [String.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_encoder_property({property_name, property_path}, required,
    schema_def, schema_dict) do

    {resolved_type, resolved_schema} =
      property_path
      |> Printer.resolve_type!(schema_def, schema_dict)

    encoder_name = create_encoder_name(
      {resolved_type, resolved_schema}, schema_def)
    is_required = property_name in required

    %{name: property_name,
      encoder_name: encoder_name,
      required: is_required}
  end

end
