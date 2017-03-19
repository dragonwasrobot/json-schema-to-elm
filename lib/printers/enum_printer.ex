defmodule JS2E.Printers.EnumPrinter do
  @moduledoc """
  A printer for printing an 'enum' type decoder.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Printers.Util
  alias JS2E.Types.EnumType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%EnumType{name: name,
                           path: _path,
                           type: type,
                           values: values}, _type_dict, _schema_dict) do

    indent = Util.indent

    values =
      values
      |> Enum.map(&(print_clause(&1, type)))
      |> Enum.join("\n#{indent}| ")

    type_name = Util.upcase_first name

    """
    type #{type_name}
    #{indent}= #{values}
    """
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%EnumType{name: name,
                              path: _path,
                              type: type,
                              values: values}, _type_dict, _schema_dict) do

    declaration = print_declaration(name, type)
    cases = print_cases(values, type)
    default_case = print_default_case(name)

    declaration <> cases <> "\n" <> default_case
  end

  @spec print_declaration(String.t, String.t) :: String.t
  defp print_declaration(name, type) do

    indent = Util.indent
    type_name = Util.upcase_first name
    decoder_name = Util.downcase_first name
    type_value = print_type_value type

    """
    #{decoder_name}Decoder : #{type_value} -> Decoder #{type_name}
    #{decoder_name}Decoder #{name} =
    #{indent}case #{name} of
    """
  end

  defp print_type_value(type) do
    case type do
      "string" ->
        "String"

      "integer" ->
        "Int"

      "number" ->
        "Float"

      _ ->
        raise "Unknown enum type: #{type}"
    end
  end

  @spec print_cases([String.t], String.t) :: String.t
  defp print_cases(values, type) do
    double_indent = Util.indent 2
    triple_indent = Util.indent 3

    Enum.map_join(values, "\n", fn value ->

      printed_raw_value = print_case(value, type)
      printed_parsed_value = print_clause(value, type)

      "#{double_indent}#{printed_raw_value} ->\n" <>
        "#{triple_indent}succeed #{printed_parsed_value}\n"
    end)
  end

  defp print_case(value, type) do
    case type do
      "string" ->
        "\"#{value}\""

      "integer" ->
        value

      "number" ->
        value

      _ ->
        raise "Unknown or unsupported enum type: #{type}"
    end
  end

  defp print_clause(value, type) do
    case type do
      "string" ->
        Util.upcase_first value

      "integer" ->
        "Int#{value}"

      "number" ->
        "Float#{value}"
        |> String.replace(".", "_")
        |> String.replace("-", "Neg")

      _ ->
        raise "Unknown or unsupported enum type: #{type}"
    end
  end

  @spec print_default_case(String.t) :: String.t
  defp print_default_case(name) do
    double_indent = Util.indent 2
    triple_indent = Util.indent 3

    """
    #{double_indent}_ ->
    #{triple_indent}fail <| "Unknown #{name} type: " ++ #{name}
    """
  end

end
