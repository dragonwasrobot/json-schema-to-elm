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
    type_name = Util.upcase_first name
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

  @spec print_field_name(String.t) :: String.t
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
      Util.upcase_first property_type.name
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

    indent = Util.indent
    decoder_name = Util.downcase_first name
    type_name = Util.upcase_first name

    decoder_properties = print_decoder_properties(
      properties, required, type_dict, schema_dict)

    """
    #{decoder_name}Decoder : Decoder #{type_name}
    #{decoder_name}Decoder =
    #{indent}decode #{type_name}
    #{decoder_properties}
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
    |> Enum.map_join("\n", fn property_name ->
      print_decoder_property(property_name, required, type_dict, schema_dict)
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

    property_type = Printer.resolve_type(property_path, type_dict, schema_dict)
    decoder_name = print_decoder_name(property_type)

    cond do
      union_type?(property_type) ->
        print_custom_clause(property_name, decoder_name)

      property_name in required ->
        print_required_clause(property_name, decoder_name)

      true ->
        print_optional_clause(property_name, decoder_name)
    end
  end

  @spec print_decoder_name(Types.typeDefinition) :: String.t
  defp print_decoder_name(property_type) do

    if primitive_type?(property_type) do
      property_type_value = property_type.type

      case property_type_value do
        "integer" ->
          "int"

        "number" ->
          "float"

        _ ->
          property_type_value
      end

    else
      "#{property_type.name}Decoder"
    end
  end

  defp primitive_type?(type) do
    Util.get_string_name(type) == "PrimitiveType"
  end

  defp union_type?(type) do
    Util.get_string_name(type) == "UnionType"
  end

  defp print_custom_clause(property_name, decoder_name) do
    double_indent = Util.indent(2)
    "#{double_indent}|> " <>
      "custom (field \"#{property_name}\" #{decoder_name})"
  end

  defp print_required_clause(property_name, decoder_name) do
    double_indent = Util.indent(2)
    "#{double_indent}|> " <>
      "required \"#{property_name}\" #{decoder_name}"
  end

  defp print_optional_clause(property_name, decoder_name) do
    double_indent = Util.indent(2)
    "#{double_indent}|> " <>
      "optional \"#{property_name}\" (nullable #{decoder_name}) Nothing"
  end

end
