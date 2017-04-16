defmodule JS2E.Printers.ObjectPrinter do
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
  alias JS2E.Types.ObjectType

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :fields])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :type_name, :clauses])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :properties])

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%ObjectType{name: name,
                             path: _path,
                             properties: properties,
                             required: required}, type_dict, schema_dict) do

    type_name = if name == "#" do
      "Root"
    else
      upcase_first name
    end

    fields = create_type_fields(properties, required, type_dict, schema_dict)

    type_template(type_name, fields)
  end

  @spec create_type_fields(
    Types.propertyDictionary,
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: [map]
  defp create_type_fields(properties, required, type_dict, schema_dict) do

    properties
    |> Enum.map(&(create_type_field(&1, required, type_dict, schema_dict)))
  end

  @spec create_type_field(
    {String.t, String.t},
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: map
  defp create_type_field({property_name, property_path},
    required, type_dict, schema_dict) do

    field_type =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)
      |> create_type_name
      |> (fn (field_name) ->
      if property_name in required do
        field_name
      else
        "Maybe #{field_name}"
      end
    end).()

    %{name: property_name,
      type: field_type}
  end

  @spec create_type_name(Types.typeDefinition) :: String.t
  defp create_type_name(property_type) do

    if primitive_type?(property_type) do
      property_type_value = property_type.type

      case property_type_value do
        "integer" ->
          "Int"

        "number" ->
          "Float"

        _ ->
          upcase_first property_type_value
      end

    else

      property_type_name = property_type.name
      if property_type_name == "#" do
        "Root"
      else
        upcase_first property_type_name
      end

    end
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    type_dict, schema_dict) do

    decoder_name = if name == "#" do
      "rootDecoder"
    else
      "#{downcase_first name}Decoder"
    end

    type_name = if name == "#" do
      "Root"
    else
      upcase_first name
    end

    clauses = create_decoder_properties(
      properties, required, type_dict, schema_dict)

    decoder_template(decoder_name, type_name, clauses)
  end

  @spec create_decoder_properties(
    Types.propertyDictionary,
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: [map]
  defp create_decoder_properties(properties, required, type_dict, schema_dict) do

    properties
    |> Enum.map(fn property ->
      create_decoder_property(property, required, type_dict, schema_dict)
    end)
  end

  @spec create_decoder_property(
    {String.t, String.t},
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: map
  defp create_decoder_property({property_name, property_path},
    required, type_dict, schema_dict) do

    property_type =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)

    decoder_name = create_decoder_name(property_type)
    is_required = property_name in required

    cond do
      union_type?(property_type) || one_of_type?(property_type) ->
        create_decoder_union_clause(property_name, decoder_name, is_required)

      enum_type?(property_type) ->
        property_type_decoder =
          property_type.type
          |> determine_primitive_type_decoder()

        create_decoder_enum_clause(property_name, property_type_decoder,
          decoder_name, is_required)

      true ->
        create_decoder_normal_clause(property_name, decoder_name, is_required)
    end
  end

  @spec determine_primitive_type_decoder(String.t) :: String.t
  defp determine_primitive_type_decoder(property_type_value) do
    case property_type_value do
      "integer" ->
        "Decode.int"

      "number" ->
        "Decode.float"

      _ ->
        "Decode.#{property_type_value}"
    end
  end

  @spec create_decoder_name(Types.typeDefinition) :: String.t
  defp create_decoder_name(property_type) do

    if primitive_type?(property_type) do
      determine_primitive_type_decoder(property_type.type)
    else

      property_type_name = property_type.name
      if property_type_name == "#" do
        "rootDecoder"
      else
        "#{property_type_name}Decoder"
      end

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

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%ObjectType{name: name,
                                path: _path,
                                properties: properties,
                                required: required},
    type_dict, schema_dict) do

    type_name = if name == "#", do: "Root", else: upcase_first name
    encoder_name = "encode#{type_name}"
    argument_name = downcase_first type_name

    properties = create_encoder_properties(properties, required,
      type_dict, schema_dict)

    template = encoder_template(encoder_name, type_name,
      argument_name, properties)
    trim_newlines(template)
  end

  @spec create_encoder_properties(
    Types.propertyDictionary,
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: [map]
  defp create_encoder_properties(properties, required, type_dict, schema_dict) do

    properties
    |> Enum.map(fn property ->
      create_encoder_property(property, required, type_dict, schema_dict)
    end)
  end

  @spec create_encoder_property(
    {String.t, String.t},
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: map
  defp create_encoder_property({property_name, property_path}, required,
    type_dict, schema_dict) do

    property_type =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)

    encoder_name = create_encoder_name(property_type)
    is_required = property_name in required

    %{name: property_name,
      encoder_name: encoder_name,
      required: is_required}
  end

end
