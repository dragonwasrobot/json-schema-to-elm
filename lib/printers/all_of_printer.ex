defmodule JS2E.Printers.AllOfPrinter do
  @moduledoc """
  A printer for printing an 'all of' type decoder.
  """

  require Logger
  import JS2E.Printers.Util
  alias JS2E.{Printer, TypePath, Types}
  alias JS2E.Types.AllOfType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%AllOfType{name: name,
                            path: _path,
                            types: types}, type_dict, schema_dict) do

    type_name = upcase_first name
    printed_types = print_types(types, type_dict, schema_dict)

    """
    type alias #{type_name} =
    #{indent()}{#{printed_types}
    #{indent()}}
    """
  end

  @spec print_types(
    [TypePath.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_types(types, type_dict, schema_dict) do

    types
    |> Enum.map(&(print_type_path(&1, type_dict, schema_dict)))
    |> Enum.join("\n#{indent()},")
  end

  @spec print_type_path(
    TypePath.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_type_path(type_path, type_dict, schema_dict) do

    type_name =
      type_path
      |> Printer.resolve_type(type_dict, schema_dict)
      |> print_type_name

    field_name = downcase_first type_name

    " #{field_name} : #{type_name}"
  end

  @spec print_type_name(Types.typeDefinition) :: String.t
  defp print_type_name(property_type) do

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
      property_type_name = upcase_first property_type.name
    end
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%AllOfType{name: name,
                               path: _path,
                               types: type_paths},
    type_dict, schema_dict) do

    decoder_declaration = print_decoder_declaration(name)
    decoder_properties = print_decoder_properties(
      type_paths, type_dict, schema_dict)

    decoder_declaration <> decoder_properties <> "\n"
  end

  @spec print_decoder_declaration(String.t) :: String.t
  defp print_decoder_declaration(name) do

    decoder_name = downcase_first name
    type_name = upcase_first name

    """
    #{decoder_name}Decoder : Decoder #{type_name}
    #{decoder_name}Decoder =
    #{indent()}decode #{type_name}
    """
  end

  @spec print_decoder_properties(
    [TypePath.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_decoder_properties(type_paths, type_dict, schema_dict) do

    type_paths
    |> Enum.map_join("\n", fn type_path ->
      print_decoder_property(type_path, type_dict, schema_dict)
    end)
  end

  @spec print_decoder_property(
    TypePath.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_decoder_property(type_path, type_dict, schema_dict) do

    property_type =
      type_path
      |> Printer.resolve_type(type_dict, schema_dict)

    property_name = property_type.name
    decoder_name = print_decoder_name(property_type)

    cond do
      union_type?(property_type) || one_of_type?(property_type) ->
        print_decoder_union_clause(property_name, decoder_name)

      enum_type?(property_type) ->
        property_type_decoder =
          property_type.type
          |> determine_primitive_type_decoder()

        print_decoder_enum_clause(
          property_name, property_type_decoder, decoder_name)

      true ->
        print_decoder_normal_clause(property_name, decoder_name)
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

  @spec print_decoder_name(Types.typeDefinition) :: String.t
  defp print_decoder_name(property_type) do

    if primitive_type?(property_type) do
      determine_primitive_type_decoder(property_type.type)
    else
      property_type_name = property_type.name
      "#{property_type_name}Decoder"
    end
  end

  defp primitive_type?(type) do
    get_string_name(type) == "PrimitiveType"
  end

  defp enum_type?(type) do
    get_string_name(type) == "EnumType"
  end

  defp one_of_type?(type) do
    get_string_name(type) == "OneOfType"
  end

  defp union_type?(type) do
    get_string_name(type) == "UnionType"
  end

  defp print_decoder_union_clause(property_name, decoder_name) do
    "#{indent(2)}|> " <>
      "required \"#{property_name}\" #{decoder_name}"
  end

  defp print_decoder_enum_clause(
    property_name,
    property_type_decoder,
    decoder_name) do

    "#{indent(2)}|> " <>
      "required \"#{property_name}\" (#{property_type_decoder} |> " <>
      "andThen #{decoder_name})"
  end

  defp print_decoder_normal_clause(property_name, decoder_name) do
    "#{indent(2)}|> " <>
      "required \"#{property_name}\" #{decoder_name}"
  end

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%AllOfType{name: name,
                               path: _path,
                               types: type_paths},
    type_dict, schema_dict) do

    type_name = upcase_first name
    argument_name = downcase_first type_name

    encoder_declaration = print_encoder_declaration(name)

    encoder_properties = print_encoder_properties(
      type_paths, argument_name, type_dict, schema_dict)

    encoder_declaration <> encoder_properties
  end

  @spec print_encoder_declaration(String.t) :: String.t
  defp print_encoder_declaration(name) do

    type_name = upcase_first name
    encoder_name = "encode#{type_name}"
    argument_name = downcase_first type_name

    """
    #{encoder_name} : #{type_name} -> Value
    #{encoder_name} #{argument_name} =
    #{indent()}let
    """
  end

  @spec print_encoder_properties(
    [TypePath.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_encoder_properties(type_paths, argument_name,
    type_dict, schema_dict) do

    encoder_properties =
      type_paths
      |> Enum.map_join("\n", fn type_path ->
      print_encoder_property(type_path, argument_name, type_dict, schema_dict)
    end)

    object_properties =
        type_paths
        |> Enum.map_join(" ++ ", fn type_path ->
      resolved_type =
        Printer.resolve_type(type_path, type_dict, schema_dict)
      resolved_type.name
    end)

    String.trim_trailing(encoder_properties) <> "\n" <>
    """
    #{indent()}in
    #{indent(2)}object <|
    #{indent(3)}#{object_properties}
    """
  end

  @spec print_encoder_property(
    TypePath.t,
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_encoder_property(type_path, argument_name,
    type_dict, schema_dict) do

    property_type =
      type_path
      |> Printer.resolve_type(type_dict, schema_dict)
    property_name = property_type.name

    encoder_name = print_encoder_name(property_type)

    encode_clause =
      print_encoder_clause(property_name, encoder_name, argument_name)

    "#{indent(2)}#{property_name} =\n#{encode_clause}\n"
  end

  defp print_encoder_name(property_type) do

    if primitive_type?(property_type) do
      determine_primitive_type_encoder(property_type.type)
    else
      property_type_name = property_type.name
      "encode#{upcase_first property_type_name}"
    end
  end

  @spec print_encoder_clause(String.t, String.t, String.t) :: String.t
  defp print_encoder_clause(
    property_name,
    encoder_name,
    argument_name) do

    property_key = "#{argument_name}.#{property_name}"

    "#{indent(3)}#{encoder_name} #{property_key}"
    |> String.trim_trailing()
  end

  @spec determine_primitive_type_encoder(String.t) :: String.t
  defp determine_primitive_type_encoder(property_type_value) do
    case property_type_value do
      "integer" ->
        "Encode.int"

      "number" ->
        "Encode.float"

      _ ->
        "Encode.#{property_type_value}"
    end
  end

end
