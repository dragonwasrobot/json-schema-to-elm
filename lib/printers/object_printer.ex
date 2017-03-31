defmodule JS2E.Printers.ObjectPrinter do
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Logger
  alias JS2E.{Printer, Types}
  alias JS2E.Printers.Util
  alias JS2E.Types.ObjectType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%ObjectType{name: name,
                             path: _path,
                             properties: properties,
                             required: required}, type_dict, schema_dict) do

    indent = Util.indent

    type_name = if name == "#" do
      "Root"
    else
      Util.upcase_first name
    end

    fields = print_fields(properties, required, type_dict, schema_dict)

    """
    type alias #{type_name} =
    #{indent}{#{fields}
    #{indent}}
    """
  end

  @spec print_fields(
    Types.propertyDictionary,
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_fields(properties, required, type_dict, schema_dict) do
    indent = Util.indent

    properties
    |> Enum.map(&(print_type_property(&1, required, type_dict, schema_dict)))
    |> Enum.join("\n#{indent},")
  end

  @spec print_type_property(
    {String.t, String.t},
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_type_property({property_name, property_path},
    required, type_dict, schema_dict) do

    field_name =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)
      |> print_field_name

    if property_name in required do
      " #{property_name} : #{field_name}"
    else
      " #{property_name} : Maybe #{field_name}"
    end
  end

  @spec print_field_name(Types.typeDefinition) :: String.t
  defp print_field_name(property_type) do

    if primitive_type?(property_type) do
      property_type_value = property_type.type

      case property_type_value do
        "integer" ->
          "Int"

        "number" ->
          "Float"

        _ ->
          Util.upcase_first property_type_value
      end

    else

      property_type_name = property_type.name
      if property_type_name == "#" do
        "Root"
      else
        Util.upcase_first property_type_name
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

    decoder_declaration = print_decoder_declaration(name)

    decoder_properties = print_decoder_properties(
      properties, required, type_dict, schema_dict)

    decoder_declaration <> decoder_properties <> "\n"
  end

  @spec print_decoder_declaration(String.t) :: String.t
  defp print_decoder_declaration(name) do
    indent = Util.indent

    decoder_name = if name == "#", do: "root", else: Util.downcase_first name
    type_name = if name == "#", do: "Root", else: Util.upcase_first name

    """
    #{decoder_name}Decoder : Decoder #{type_name}
    #{decoder_name}Decoder =
    #{indent}decode #{type_name}
    """
  end

  @spec print_decoder_properties(
    Types.propertyDictionary,
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_decoder_properties(properties, required, type_dict, schema_dict) do

    properties
    |> Enum.map_join("\n", fn property ->
      print_decoder_property(property, required, type_dict, schema_dict)
    end)
  end

  @spec print_decoder_property(
    {String.t, String.t},
    [String.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_decoder_property({property_name, property_path},
    required, type_dict, schema_dict) do

    property_type =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)

    decoder_name = print_decoder_name(property_type)

    is_required = property_name in required

    cond do
      union_type?(property_type) || one_of_type?(property_type) ->
        print_decoder_union_clause(property_name, decoder_name, is_required)

      enum_type?(property_type) ->
        property_type_decoder =
          property_type.type
          |> determine_primitive_type_decoder()

        print_decoder_enum_clause(property_name, property_type_decoder,
          decoder_name, is_required)

      true ->
        print_decoder_normal_clause(property_name, decoder_name, is_required)
    end
  end

  @spec determine_primitive_type_decoder(String.t) :: String.t
  defp determine_primitive_type_decoder(property_type_value) do
    case property_type_value do
      "integer" ->
        "int"

      "number" ->
        "float"

      _ ->
        property_type_value
    end
  end

  @spec print_decoder_name(Types.typeDefinition) :: String.t
  defp print_decoder_name(property_type) do

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

  defp primitive_type?(type) do
    Util.get_string_name(type) == "PrimitiveType"
  end

  defp enum_type?(type) do
    Util.get_string_name(type) == "EnumType"
  end

  defp one_of_type?(type) do
    Util.get_string_name(type) == "OneOfType"
  end

  defp union_type?(type) do
    Util.get_string_name(type) == "UnionType"
  end

  defp print_decoder_union_clause(property_name, decoder_name, is_required) do
    double_indent = Util.indent(2)

    if is_required do
      "#{double_indent}|> " <>
        "required \"#{property_name}\" #{decoder_name}"

    else
      "#{double_indent}|> " <>
        "optional \"#{property_name}\" (nullable #{decoder_name}) Nothing"
    end
  end

  defp print_decoder_enum_clause(
    property_name,
    property_type_decoder,
    decoder_name,
    is_required) do

    double_indent = Util.indent(2)

    if is_required do
      "#{double_indent}|> " <>
        "required \"#{property_name}\" (#{property_type_decoder} |> " <>
        "andThen #{decoder_name})"

    else
      "#{double_indent}|> " <>
        "optional \"#{property_name}\" (#{property_type_decoder} |> " <>
        "andThen #{decoder_name} |> maybe) Nothing"
    end
  end

  defp print_decoder_normal_clause(property_name, decoder_name, is_required) do
    double_indent = Util.indent(2)

    if is_required do
      "#{double_indent}|> " <>
        "required \"#{property_name}\" #{decoder_name}"

    else
      "#{double_indent}|> " <>
        "optional \"#{property_name}\" (nullable #{decoder_name}) Nothing"
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

    type_name = if name == "#", do: "Root", else: Util.upcase_first name
    argument_name = Util.downcase_first type_name

    encoder_declaration = print_encoder_declaration(name)

    encoder_properties = print_encoder_properties(
      properties, required, argument_name, type_dict, schema_dict)

    encoder_declaration <> encoder_properties
  end

  @spec print_encoder_declaration(String.t) :: String.t
  defp print_encoder_declaration(name) do
    indent = Util.indent

    type_name = if name == "#", do: "Root", else: Util.upcase_first name
    encoder_name = "encode#{type_name}"
    argument_name = Util.downcase_first type_name

    """
    #{encoder_name} : #{type_name} -> Value
    #{encoder_name} #{argument_name} =
    #{indent}let
    """
  end

  @spec print_encoder_properties(
    Types.propertyDictionary,
    [String.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_encoder_properties(properties, required, argument_name,
    type_dict, schema_dict) do

    indent = Util.indent
    double_indent = Util.indent(2)
    triple_indent = Util.indent(3)

    encoder_properties =
      properties
      |> Enum.map_join("\n", fn property ->
      print_encoder_property(property, required, argument_name,
        type_dict, schema_dict)
    end)

    object_properties =
        properties
        |> Enum.map_join(" ++ ", fn {property_name, _} -> property_name end)

    String.trim_trailing(encoder_properties) <> "\n" <>
    """
    #{indent}in
    #{double_indent}object <|
    #{triple_indent}#{object_properties}
    """
  end

  @spec print_encoder_property(
    {String.t, String.t},
    [String.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_encoder_property({property_name, property_path}, required,
    argument_name, type_dict, schema_dict) do
    double_indent = Util.indent(2)

    property_type =
      property_path
      |> Printer.resolve_type(type_dict, schema_dict)

    encoder_name = print_encoder_name(property_type)

    is_required = property_name in required

    encode_clause =
      print_encoder_clause(property_name, encoder_name,
        argument_name, is_required)

    "#{double_indent}#{property_name} =\n#{encode_clause}\n"
  end

  defp print_encoder_name(property_type) do

    if primitive_type?(property_type) do
      determine_primitive_type_encoder(property_type.type)
    else

      property_type_name = property_type.name
      if property_type_name == "#" do
        "encodeRoot"
      else
        "encode#{Util.upcase_first property_type_name}"
      end

    end
  end

  @spec print_encoder_clause(String.t, String.t, String.t, boolean) :: String.t
  defp print_encoder_clause(
    property_name,
    encoder_name,
    argument_name,
    is_required) do

    triple_indent = Util.indent(3)
    quadruple_indent = Util.indent(4)
    quintuple_indent = Util.indent(5)

    property_key = "#{argument_name}.#{property_name}"

    if is_required do
      "#{triple_indent}[ ( \"#{property_name}\", #{encoder_name} #{property_key} ) ]"
    else
      """
      #{triple_indent}case #{property_key} of
      #{quadruple_indent}Just #{property_name} ->
      #{quintuple_indent}[ ( "#{property_name}", #{encoder_name} #{property_name} ) ]

      #{quadruple_indent}Nothing ->
      #{quintuple_indent}[]
      """
    end
  end

  @spec determine_primitive_type_encoder(String.t) :: String.t
  defp determine_primitive_type_encoder(property_type_value) do
    case property_type_value do
      "integer" ->
        "int"

      "number" ->
        "float"

      _ ->
        property_type_value
    end
  end

end
