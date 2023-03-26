defmodule JS2E.Printer.ArrayPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'array' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.{Parser, Resolver, Types}
  alias Parser.ParserError
  alias Printer.{PrinterError, PrinterResult, Utils}

  alias Types.{ArrayType, PrimitiveType, SchemaDefinition}

  alias Utils.{
    ElmDecoders,
    ElmEncoders,
    ElmFuzzers,
    ElmTypes,
    Naming
  }

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %ArrayType{name: _name, path: _path, items: _items_path},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "decoders/list_decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :list_decoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %ArrayType{name: name, path: path, items: items_path},
        schema_def,
        schema_dict,
        _module_name
      ) do
    with {:ok, {items_type, _resolved_schema_def}} <-
           Resolver.resolve_type(items_path, path, schema_def, schema_dict),
         {:ok, items_type_name} <- determine_type_name(items_type),
         {:ok, items_decoder_name} <- determine_decoder_name(items_type) do
      %{
        name: "#{Naming.normalize_identifier(name, :downcase)}Decoder",
        type: items_type_name,
        item_decoder: items_decoder_name
      }
      |> decoder_template()
      |> PrinterResult.new()
    else
      {:error, %ParserError{identifier: id, error_type: atom, message: str}} ->
        PrinterResult.new("", [PrinterError.new(id, atom, str)])

      {:error, printer_error} ->
        PrinterResult.new("", [printer_error])
    end
  end

  @spec determine_type_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_type_name(items_type) do
    case items_type do
      %PrimitiveType{} ->
        {:ok, ElmTypes.determine_primitive_type_name(items_type.type)}

      _ ->
        items_type_name = Naming.normalize_identifier(items_type.name, :upcase)

        if items_type_name == "Hash" do
          {:ok, "Root"}
        else
          {:ok, items_type_name}
        end
    end
  end

  @spec determine_decoder_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_decoder_name(items_type) do
    case items_type do
      %PrimitiveType{} ->
        {:ok, ElmDecoders.determine_primitive_type_decoder(items_type.type)}

      _ ->
        items_type_name = Naming.normalize_identifier(items_type.name, :downcase)

        if items_type_name == "hash" do
          {:ok, "rootDecoder"}
        else
          {:ok, "#{items_type_name}Decoder"}
        end
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/list_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :list_encoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %ArrayType{name: name, path: path, items: items_path},
        schema_def,
        schema_dict,
        _module_name
      ) do
    with {:ok, {items_type, _resolved_schema_def}} <-
           Resolver.resolve_type(items_path, path, schema_def, schema_dict),
         {:ok, items_type_name} <- determine_type_name(items_type),
         {:ok, items_encoder_name} <- determine_encoder_name(items_type) do
      %{
        name: "encode#{Naming.normalize_identifier(name, :upcase)}",
        type: items_type_name,
        argument_name: name,
        items_encoder: items_encoder_name
      }
      |> encoder_template()
      |> PrinterResult.new()
    else
      {:error, %ParserError{identifier: id, error_type: atom, message: str}} ->
        PrinterResult.new("", [PrinterError.new(id, atom, str)])

      {:error, printer_error} ->
        PrinterResult.new("", [printer_error])
    end
  end

  @spec determine_encoder_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_encoder_name(items_type) do
    case items_type do
      %PrimitiveType{} ->
        {:ok, ElmEncoders.determine_primitive_type_encoder(items_type.type)}

      _ ->
        items_type_name = Naming.normalize_identifier(items_type.name, :upcase)

        if items_type_name == "Hash" do
          {:ok, "encodeRoot"}
        else
          {:ok, "encode#{items_type_name}"}
        end
    end
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/list_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [
    :list_fuzzer
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %ArrayType{name: name, path: path, items: items_path},
        schema_def,
        schema_dict,
        _module_name
      ) do
    with {:ok, {items_type, _resolved_schema_def}} <-
           Resolver.resolve_type(items_path, path, schema_def, schema_dict),
         {:ok, items_type_name} <- determine_type_name(items_type),
         {:ok, items_fuzzer_name} <- determine_fuzzer_name(items_type) do
      array_name = Naming.normalize_identifier(name, :upcase)
      argument_name = Naming.normalize_identifier(name, :downcase)
      fuzzer_name = "#{name}Fuzzer"
      decoder_name = "#{Naming.normalize_identifier(name, :downcase)}Decoder"
      encoder_name = "encode#{Naming.normalize_identifier(name, :upcase)}"

      %{
        name: fuzzer_name,
        array_name: array_name,
        items_type: items_type_name,
        items_fuzzer: items_fuzzer_name,
        argument_name: argument_name,
        decoder_name: decoder_name,
        encoder_name: encoder_name
      }
      |> fuzzer_template()
      |> PrinterResult.new()
    else
      {:error, %ParserError{identifier: id, error_type: atom, message: str}} ->
        PrinterResult.new("", [PrinterError.new(id, atom, str)])

      {:error, printer_error} ->
        PrinterResult.new("", [printer_error])
    end
  end

  @spec determine_fuzzer_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_fuzzer_name(items_type) do
    case items_type do
      %PrimitiveType{} ->
        {:ok, ElmFuzzers.determine_primitive_fuzzer_name(items_type.type)}

      _ ->
        items_type_name = Naming.normalize_identifier(items_type.name, :downcase)

        if items_type_name == "hash" do
          {:ok, "rootFuzzer"}
        else
          {:ok, "#{items_type_name}Fuzzer"}
        end
    end
  end
end
