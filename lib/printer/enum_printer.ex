defmodule JS2E.Printer.EnumPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  Prints the Elm type, JSON decoder and JSON eecoder for a JSON schema 'enum'.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.{PrinterResult, Utils}
  alias Types.{EnumType, SchemaDefinition}
  alias Utils.{Indentation, Naming}

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "types/sum_type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [:sum_type])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %EnumType{name: name, path: _path, type: type, values: values},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    clauses =
      values
      |> Enum.map(&create_elm_value(&1, type))

    name =
      name
      |> Naming.normalize_identifier(:upcase)

    %{name: name, clauses: {:anonymous, clauses}}
    |> type_template()
    |> PrinterResult.new()
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "decoders/enum_decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [:enum_decoder])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %EnumType{name: name, path: _path, type: type, values: values},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    decoder_name = "#{Naming.normalize_identifier(name, :downcase)}Decoder"
    decoder_type = Naming.upcase_first(name)
    argument_type = to_elm_type_name(type)
    parser_name = "parse#{Naming.normalize_identifier(name, :upcase)}"

    clauses =
      values
      |> create_decoder_clauses(type)

    %{
      name: decoder_name,
      type: decoder_type,
      argument_name: name,
      argument_type: argument_type,
      parser_name: parser_name,
      clauses: clauses
    }
    |> decoder_template()
    |> PrinterResult.new()
  end

  @spec to_elm_type_name(EnumType.value_type()) :: String.t()
  defp to_elm_type_name(type_name) do
    case type_name do
      :string -> "string"
      :integer -> "int"
      :number -> "float"
    end
  end

  @spec create_decoder_clauses([String.t()], String.t()) :: [map]
  defp create_decoder_clauses(values, type_name) do
    values
    |> Enum.map(fn value ->
      raw_value = create_decoder_case(value, type_name)
      parsed_value = create_elm_value(value, type_name)
      %{raw_value: raw_value, parsed_value: parsed_value}
    end)
  end

  @spec create_decoder_case(String.t(), EnumType.value_type()) :: String.t()
  defp create_decoder_case(value, type_name) do
    case type_name do
      :string -> "\"#{value}\""
      :integer -> value
      :number -> value
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/enum_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :enum_encoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %EnumType{name: name, path: _path, type: type, values: values},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    argument_type = Naming.normalize_identifier(name, :upcase)
    encoder_name = "encode#{argument_type}"
    argument_js_type = to_elm_type_name(type) |> String.capitalize()

    clauses =
      values
      |> create_encoder_cases(type)

    %{
      name: encoder_name,
      type: argument_type,
      argument_name: name,
      argument_js_type: argument_js_type,
      clauses: clauses
    }
    |> encoder_template()
    |> Indentation.trim_newlines()
    |> PrinterResult.new()
  end

  @spec create_encoder_cases([String.t() | number], String.t()) :: [map]
  defp create_encoder_cases(values, type_name) do
    values
    |> Enum.map(fn value ->
      elm_value = create_elm_value(value, type_name)
      json_value = create_encoder_case(value, type_name)
      %{elm_value: elm_value, json_value: json_value}
    end)
  end

  @spec create_encoder_case(String.t() | number, EnumType.value_type()) :: String.t()
  defp create_encoder_case(value, type_name) do
    case type_name do
      :string -> "\"#{value}\""
      :integer -> "#{value}"
      :number -> "#{value}"
    end
  end

  @spec create_elm_value(String.t(), EnumType.value_type()) :: String.t()
  defp create_elm_value(value, type_name) do
    case type_name do
      :string ->
        Naming.normalize_identifier(value, :upcase)

      :integer ->
        "Int#{value}"

      :number ->
        "Float#{value}"
        |> String.replace(".", "_")
        |> String.replace("-", "Neg")
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/sum_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [:sum_fuzzer])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %EnumType{name: name, path: _path, type: _type, values: values},
        schema_def,
        _schema_dict,
        _module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.normalize_identifier(type_name, :downcase)
    decoder_name = "#{Naming.normalize_identifier(type_name, :downcase)}Decoder"
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"
    fuzzer_name = "#{Naming.normalize_identifier(type_name, :downcase)}Fuzzer"

    fuzzers =
      values
      |> Enum.map(fn clause_fuzzer ->
        "Fuzz.constant #{Naming.normalize_identifier(clause_fuzzer, :upcase)}"
      end)

    %{
      name: fuzzer_name,
      type: type_name,
      argument_name: argument_name,
      encoder_name: encoder_name,
      decoder_name: decoder_name,
      clause_fuzzers: List.flatten(fuzzers)
    }
    |> fuzzer_template()
    |> PrinterResult.new()
  end
end
