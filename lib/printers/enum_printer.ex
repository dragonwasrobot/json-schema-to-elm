defmodule JS2E.Printers.EnumPrinter do
  @moduledoc """
  Prints the Elm type, JSON decoder and JSON eecoder for a JSON schema 'enum'.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @type_location Path.join(@templates_location, "enum/type.elm.eex")
  @decoder_location Path.join(@templates_location, "enum/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "enum/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.Types
  alias JS2E.Types.EnumType

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :clauses])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :decoder_type, :argument_name, :argument_type, :cases])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :argument_name, :argument_type, :cases])

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%EnumType{name: name,
                           path: _path,
                           type: type,
                           values: values}, _type_dict, _schema_dict) do

    type_name = upcase_first name
    clauses = values |> Enum.map(&(create_elm_value(&1, type)))

    type_template(type_name, clauses)
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

    decoder_name = "#{downcase_first name}Decoder"
    argument_type = create_type_value type
    decoder_type = upcase_first name
    cases = create_decoder_cases(values, type)

    decoder_template(decoder_name, decoder_type, name, argument_type, cases)
  end

  @spec create_type_value(String.t) :: String.t
  defp create_type_value(type) do
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

  @spec create_decoder_cases([String.t], String.t) :: [map]
  defp create_decoder_cases(values, type) do

    values |> Enum.map(fn value ->
      raw_value = create_decoder_case(value, type)
      parsed_value = create_elm_value(value, type)

      %{raw_value: raw_value,
        parsed_value: parsed_value}
    end)
  end

  @spec create_decoder_case(String.t, String.t) :: String.t
  defp create_decoder_case(value, type) do
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

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%EnumType{name: name,
                              path: _path,
                              type: type,
                              values: values}, _type_dict, _schema_dict) do

    argument_type = upcase_first name
    encoder_name = "encode#{argument_type}"
    cases = create_encoder_cases(values, type)

    template = encoder_template(encoder_name, name, argument_type, cases)
    trim_newlines(template)
  end

  @spec create_encoder_cases([String.t | number], String.t) :: [map]
  defp create_encoder_cases(values, type) do

    values |> Enum.map(fn value ->

      elm_value = create_elm_value(value, type)
      json_value = create_encoder_case(value, type)

      %{elm_value: elm_value,
        json_value: json_value}
    end)
  end

  @spec create_encoder_case(String.t | number, String.t) :: String.t
  defp create_encoder_case(value, type) do
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

  @spec create_elm_value(String.t, String.t) :: String.t
  defp create_elm_value(value, type) do
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

end
