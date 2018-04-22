defmodule JS2E.Printer.UnionPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
  A printer for printing an 'object' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer.{Util, PrinterError, PrinterResult, ErrorUtil}
  alias JS2E.{Types}
  alias JS2E.Types.{UnionType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "union/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :type_name,
    :clauses
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    {type_clauses, errors} =
      types
      |> create_type_clauses(name)
      |> Util.split_ok_and_errors()

    name
    |> Util.upcase_first()
    |> type_template(type_clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_type_clauses([String.t()], String.t()) :: [
          {:ok, map} | {:error, PrinterError.t()}
        ]
  defp create_type_clauses(type_ids, name) do
    type_ids
    |> Enum.filter(&(&1 != "null"))
    |> Enum.map(&to_type_clause(&1, name))
  end

  @spec to_type_clause(String.t(), String.t()) ::
          {:ok, map} | {:error, PrinterError.t()}
  defp to_type_clause(type_id, name) do
    type_name = Util.upcase_first(name)

    case type_id do
      "boolean" ->
        {:ok, %{name: "#{type_name}_B", type: "Bool"}}

      "integer" ->
        {:ok, %{name: "#{type_name}_I", type: "Int"}}

      "number" ->
        {:ok, %{name: "#{type_name}_F", type: "Float"}}

      "string" ->
        {:ok, %{name: "#{type_name}_S", type: "String"}}

      unknown_type_id ->
        {:error, ErrorUtil.unknown_primitive_type(unknown_type_id)}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "union/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :decoder_name,
    :decoder_type,
    :nullable?,
    :clauses
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    decoder_name = "#{name}Decoder"
    type_name = Util.upcase_first(name)
    nullable? = "null" in types
    decoder_type = check_if_maybe(type_name, nullable?)

    {decoder_clauses, errors} =
      types
      |> create_clause_decoders(type_name, nullable?)
      |> Util.split_ok_and_errors()

    decoder_name
    |> decoder_template(decoder_type, nullable?, decoder_clauses)
    |> PrinterResult.new(errors)
  end

  @spec check_if_maybe(String.t(), boolean) :: String.t()
  defp check_if_maybe(type_name, nullable?) do
    if nullable? do
      "(Maybe #{type_name})"
    else
      type_name
    end
  end

  @spec create_clause_decoders([String.t()], String.t(), boolean) :: [
          {:ok, map} | {:error, PrinterError.t()}
        ]
  defp create_clause_decoders(type_ids, type_name, nullable?) do
    type_ids
    |> Enum.filter(fn type_id -> type_id != "null" end)
    |> Enum.map(&create_clause_decoder(&1, type_name, nullable?))
  end

  @spec create_clause_decoder(String.t(), String.t(), boolean) ::
          {:ok, map} | {:error, PrinterError.t()}
  defp create_clause_decoder(type_id, type_name, nullable?) do
    type_id_result =
      case type_id do
        "boolean" ->
          {:ok, {"_B", "Decode.bool"}}

        "integer" ->
          {:ok, {"_I", "Decode.int"}}

        "number" ->
          {:ok, {"_F", "Decode.float"}}

        "string" ->
          {:ok, {"_S", "Decode.string"}}

        unknown_type_id ->
          {:error, ErrorUtil.unknown_primitive_type(unknown_type_id)}
      end

    case type_id_result do
      {:ok, {constructor_suffix, decoder_name}} ->
        constructor_name = type_name <> constructor_suffix

        wrapper =
          if nullable? do
            "succeed << Just"
          else
            "succeed"
          end

        {:ok,
         %{
           decoder_name: decoder_name,
           constructor_name: constructor_name,
           wrapper: wrapper
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "union/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :encoder_name,
    :type_name,
    :argument_name,
    :cases
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    {encoder_cases, errors} =
      types
      |> create_encoder_cases(name)
      |> Util.split_ok_and_errors()

    type_name = Util.upcase_first(name)
    encoder_name = "encode#{type_name}"

    encoder_name
    |> encoder_template(type_name, name, encoder_cases)
    |> Util.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_cases([String.t()], String.t()) :: [
          {:ok, map} | {:error, PrinterError.t()}
        ]
  defp create_encoder_cases(type_ids, name) do
    type_ids
    |> Enum.map(&create_encoder_clause(&1, name))
  end

  @spec create_encoder_clause(String.t(), String.t()) ::
          {:ok, map} | {:error, PrinterError.t()}
  defp create_encoder_clause(type_id, name) do
    type_id_result =
      case type_id do
        "boolean" ->
          {:ok, {"_B", "Encode.bool", "boolValue"}}

        "integer" ->
          {:ok, {"_I", "Encode.int", "intValue"}}

        "number" ->
          {:ok, {"_F", "Encode.float", "floatValue"}}

        "string" ->
          {:ok, {"_S", "Encode.string", "stringValue"}}

        unknown_type_id ->
          {:error, ErrorUtil.unknown_primitive_type(unknown_type_id)}
      end

    case type_id_result do
      {:ok, {constructor_suffix, encoder_name, argument_name}} ->
        constructor_name = Util.upcase_first(name) <> constructor_suffix

        {:ok,
         %{
           constructor: "#{constructor_name} #{argument_name}",
           encoder: "#{encoder_name} #{argument_name}"
         }}

      {:error, error} ->
        {:error, error}
    end
  end
end
