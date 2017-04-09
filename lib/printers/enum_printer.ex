defmodule JS2E.Printers.EnumPrinter do
  @moduledoc """
  Prints the Elm type, JSON decoder and JSON eecoder for a JSON schema 'enum'.
  """

  require Logger
  import JS2E.Printers.Util
  alias JS2E.Types
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

    values =
      values
      |> Enum.map(&(print_elm_value(&1, type)))
      |> Enum.join("\n#{indent()}| ")

    type_name = upcase_first name

    """
    type #{type_name}
    #{indent()}= #{values}
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

    declaration = print_decoder_declaration(name, type)
    cases = print_decoder_cases(values, type)
    default_case = print_decoder_default_case(name)

    declaration <> cases <> "\n" <> default_case
  end

  @spec print_decoder_declaration(String.t, String.t) :: String.t
  defp print_decoder_declaration(name, type) do

    type_name = upcase_first name
    decoder_name = downcase_first name
    type_value = print_type_value type

    """
    #{decoder_name}Decoder : #{type_value} -> Decoder #{type_name}
    #{decoder_name}Decoder #{name} =
    #{indent()}case #{name} of
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

  @spec print_decoder_cases([String.t], String.t) :: String.t
  defp print_decoder_cases(values, type) do

    Enum.map_join(values, "\n", fn value ->

      printed_raw_value = print_decoder_case(value, type)
      printed_parsed_value = print_elm_value(value, type)

      "#{indent(2)}#{printed_raw_value} ->\n" <>
        "#{indent(3)}succeed #{printed_parsed_value}\n"
    end)
  end

  @spec print_decoder_case(String.t, String.t) :: String.t
  defp print_decoder_case(value, type) do
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

  @spec print_elm_value(String.t, String.t) :: String.t
  defp print_elm_value(value, type) do
    case type do
      "string" ->
        upcase_first value

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

  @spec print_decoder_default_case(String.t) :: String.t
  defp print_decoder_default_case(name) do

    """
    #{indent(2)}_ ->
    #{indent(3)}fail <| "Unknown #{name} type: " ++ #{name}
    """
  end

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%EnumType{name: name,
                              path: _path,
                              type: type,
                              values: values}, _type_dict, _schema_dict) do

    declaration = print_encoder_declaration(name)
    cases = print_encoder_cases(values, type)

    declaration <> cases
  end

  @spec print_encoder_declaration(String.t) :: String.t
  defp print_encoder_declaration(name) do
    type_name = upcase_first name
    encoder_name = "encode#{type_name}"

    """
    #{encoder_name} : #{type_name} -> Value
    #{encoder_name} #{name} =
    #{indent()}case #{name} of
    """
  end

  @spec print_encoder_cases([String.t | number], String.t) :: String.t
  defp print_encoder_cases(values, type) do

    Enum.map_join(values, "\n", fn value ->

      printed_elm_value = print_elm_value(value, type)
      printed_json_value = print_encoder_case(value, type)

      "#{indent(2)}#{printed_elm_value} ->\n" <>
        "#{indent(3)}#{printed_json_value}\n"
    end)
  end

  @spec print_encoder_case(String.t | number, String.t) :: String.t
  defp print_encoder_case(value, type) do
    case type do
      "string" ->
        "Encode.string \"#{value}\""

      "integer" ->
        "Encode.int #{value}"

      "number" ->
        "Encode.float #{value}"

      _ ->
        raise "Unknown or unsupported enum type: #{type}"
    end
  end

end
