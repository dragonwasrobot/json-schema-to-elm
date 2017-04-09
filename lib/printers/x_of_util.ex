defmodule JS2E.Printers.XofUtil do
  @moduledoc ~S"""
  A module containing utility functions for allOf and anyOf printers.
  """

  import JS2E.Printers.Util
  alias JS2E.{Printer, TypePath, Types}

  @spec print_encoder_declaration(String.t) :: String.t
  def print_encoder_declaration(name) do

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
    Types.schemaDictionary,
    (String.t, String.t, String.t -> String.t)
  ) :: String.t
  def print_encoder_properties(type_paths, argument_name,
    type_dict, schema_dict, print_encoder_clause) do

    encoder_properties =
      type_paths
      |> Enum.map_join("\n", fn type_path ->
      print_encoder_property(type_path, argument_name,
        type_dict, schema_dict, print_encoder_clause)
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
    Types.schemaDictionary,
    (String.t, String.t, String.t -> String.t)
  ) :: String.t
  defp print_encoder_property(type_path, argument_name,
    type_dict, schema_dict, print_encoder_clause) do

    property_type =
      type_path
      |> Printer.resolve_type(type_dict, schema_dict)
    property_name = property_type.name

    encoder_name = print_encoder_name(property_type)

    encode_clause =
      print_encoder_clause.(property_name, encoder_name, argument_name)

    "#{indent(2)}#{property_name} =\n#{encode_clause}\n"
  end

  @spec print_encoder_name(struct) :: String.t
  defp print_encoder_name(property_type) do

    if primitive_type?(property_type) do
      determine_primitive_type_encoder(property_type.type)
    else
      property_type_name = property_type.name
      "encode#{upcase_first property_type_name}"
    end
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
