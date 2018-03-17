defmodule JS2E.Printer.ArrayPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
  A printer for printing an 'array' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer.{Util, PrinterResult}
  alias JS2E.Types
  alias JS2E.Types.{ArrayType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

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

  @decoder_location Path.join(@templates_location, "array/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :decoder_name,
    :items_type_name,
    :items_decoder_name
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
           Util.resolve_type(items_path, path, schema_def, schema_dict),
         {:ok, items_type_name} <- determine_type_name(items_type),
         {:ok, items_decoder_name} <- determine_decoder_name(items_type) do
      "#{name}Decoder"
      |> Util.downcase_first()
      |> decoder_template(items_type_name, items_decoder_name)
      |> PrinterResult.new()
    else
      {:error, error} ->
        PrinterResult.new("", [error])
    end
  end

  @spec determine_type_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_type_name(items_type) do
    if Util.primitive_type?(items_type) do
      Util.determine_primitive_type(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        {:ok, "Root"}
      else
        {:ok, Util.upcase_first(items_type_name)}
      end
    end
  end

  @spec determine_decoder_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_decoder_name(items_type) do
    if Util.primitive_type?(items_type) do
      Util.determine_primitive_type_decoder(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        {:ok, "rootDecoder"}
      else
        {:ok, "#{items_type_name}Decoder"}
      end
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "array/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :encoder_name,
    :argument_name,
    :items_type_name,
    :items_encoder_name
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
           Util.resolve_type(items_path, path, schema_def, schema_dict),
         {:ok, items_type_name} <- determine_type_name(items_type),
         {:ok, items_encoder_name} <- determine_encoder_name(items_type) do
      "encode#{items_type_name}s"
      |> encoder_template(name, items_type_name, items_encoder_name)
      |> PrinterResult.new()
    else
      {:error, error} ->
        PrinterResult.new("", [error])
    end
  end

  @spec determine_encoder_name(Types.typeDefinition()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  defp determine_encoder_name(items_type) do
    if Util.primitive_type?(items_type) do
      Util.determine_primitive_type_encoder(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        {:ok, "encodeRoot"}
      else
        {:ok, "encode#{Util.upcase_first(items_type_name)}"}
      end
    end
  end
end
