defmodule JS2E.Printers.EnumPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  Prints the Elm type, JSON decoder and JSON eecoder for a JSON schema 'enum'.
  """

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util, only: [
    create_type_name: 3,
    determine_primitive_type: 1,
    downcase_first: 1,
    resolve_type: 3,
    split_ok_and_errors: 1,
    trim_newlines: 1,
    upcase_first: 1
  ]
  alias JS2E.Printers.{PrinterResult, ErrorUtil}
  alias JS2E.Types
  alias JS2E.Types.{EnumType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "enum/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :clauses])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_type(%EnumType{name: name,
                           path: _path,
                           type: type,
                           values: values},
    _schema_def, _schema_dict, _module_name) do

    {clauses, errors} =
      values
      |> Enum.map(&(create_elm_value(&1, type)))
      |> split_ok_and_errors()

    name
    |> upcase_first
    |> type_template(clauses)
    |> PrinterResult.new(errors)
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "enum/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :decoder_type, :argument_name, :argument_type, :cases])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_decoder(%EnumType{name: name,
                              path: _path,
                              type: type,
                              values: values},
    _schema_def, _schema_dict, _module_name) do

    case determine_primitive_type(type) do
      {:ok, argument_type} ->

        decoder_name = "#{downcase_first name}Decoder"
        decoder_type = upcase_first name

        {decoder_cases, errors} =
          values
          |> create_decoder_cases(type)
          |> split_ok_and_errors()

        decoder_name
        |> decoder_template(decoder_type, name, argument_type, decoder_cases)
        |> PrinterResult.new(errors)

    {:error, error} ->
        PrinterResult.new("", [error])
    end
  end

  @spec create_decoder_cases([String.t], String.t)
  :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_decoder_cases(values, type_name) do

    Enum.map(values, fn value ->
      with {:ok, raw_value} <- create_decoder_case(value, type_name),
      {:ok, parsed_value} <- create_elm_value(value, type_name)
        do
        {:ok, %{raw_value: raw_value,
                parsed_value: parsed_value}}
        else
          {:error, error} ->
            {:error, error}
      end
    end)
  end

  @spec create_decoder_case(String.t, String.t)
  :: {:ok, String.t} | {:error, PrinterError.t}
  defp create_decoder_case(value, type_name) do
    case type_name do
      "string" ->
        {:ok, "\"#{value}\""}

      "integer" ->
        {:ok, value}

      "number" ->
        {:ok, value}

      _ ->
        {:error, ErrorUtil.unknown_enum_type(type_name)}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "enum/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :argument_name, :argument_type, :cases])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary, String.t) :: PrinterResult.t
  def print_encoder(%EnumType{name: name,
                              path: _path,
                              type: type,
                              values: values},
    _schema_def, _schema_dict, _module_name) do

    argument_type = upcase_first name
    encoder_name = "encode#{argument_type}"

    {encoder_cases, errors} =
      values
      |> create_encoder_cases(type)
      |> split_ok_and_errors()

    encoder_name
    |> encoder_template(name, argument_type, encoder_cases)
    |> trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_cases([String.t | number], String.t)
  :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_encoder_cases(values, type_name) do

    Enum.map(values, fn value ->
      with {:ok, elm_value} <- create_elm_value(value, type_name),
      {:ok, json_value} <- create_encoder_case(value, type_name)
        do
        {:ok, %{elm_value: elm_value,
                json_value: json_value}}
        else
          {:error, error} ->
            {:error, error}
      end
    end)
  end

  @spec create_encoder_case(String.t | number, String.t)
  :: {:ok, String.t} | {:error, PrinterError.t}
  defp create_encoder_case(value, type_name) do
    case type_name do
      "string" ->
        {:ok, "Encode.string \"#{value}\""}

      "integer" ->
        {:ok, "Encode.int #{value}"}

      "number" ->
        {:ok, "Encode.float #{value}"}

      "boolean" ->
        {:ok, "Encode.bool #{value}"}

      "null" ->
        {:ok, "Encode.null"}

      _ ->
        {:error, ErrorUtil.unknown_enum_type(type_name)}
    end
  end

  @spec create_elm_value(String.t, String.t)
  :: {:ok, String.t} | {:error, PrinterError.t}
  defp create_elm_value(value, type_name) do

    case type_name do
      "string" ->
        {:ok, upcase_first(value)}

      "integer" ->
        {:ok, "Int#{value}"}

      "number" ->
        result =
          "Float#{value}"
          |> String.replace(".", "_")
          |> String.replace("-", "Neg")
        {:ok, result}

      _ ->
        {:error, ErrorUtil.unknown_enum_type(type_name)}
    end
  end

end
