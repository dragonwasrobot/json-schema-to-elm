defmodule JS2E.Printers.ArrayPrinter do
  @moduledoc """
  A printer for printing an 'array' type decoder.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @decoder_location Path.join(@templates_location, "array/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "array/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.{Printer, Types}
  alias JS2E.Types.ArrayType

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :items_type_name, :items_decoder_name])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :argument_name, :items_type_name, :items_encoder_name])

  @spec print_type(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%ArrayType{name: _name,
                            path: _path,
                            items: _items_path}, _schema_def, _schema_dict) do
    ""
  end

  @spec print_decoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%ArrayType{name: name,
                               path: _path,
                               items: items_path}, schema_def, schema_dict) do

    {items_type, resolved_schema_def} =
      items_path
      |> Printer.resolve_type!(schema_def, schema_dict)

    items_type_name = determine_type_name(items_type)
    items_decoder_name = determine_decoder_name(items_type)

    decoder_name = downcase_first "#{name}Decoder"

    decoder_template(decoder_name, items_type_name, items_decoder_name)
  end

  @spec determine_decoder_name(Types.typeDefinition) :: String.t
  defp determine_decoder_name(items_type) do

    if primitive_type?(items_type) do
      determine_primitive_type_decoder!(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        "rootDecoder"
      else
        "#{items_type_name}Decoder"
      end
    end
  end

  @spec determine_type_name(Types.typeDefinition) :: String.t
  defp determine_type_name(items_type) do

    if primitive_type?(items_type) do
      determine_primitive_type!(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        "Root"
      else
        upcase_first items_type_name
      end

    end
  end

  @spec print_encoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%ArrayType{name: name,
                               path: _path,
                               items: items_path}, schema_def, schema_dict) do

    {items_type, resolved_schema_def} =
      items_path
      |> Printer.resolve_type!(schema_def, schema_dict)

    items_type_name = determine_type_name(items_type)
    items_encoder_name = determine_encoder_name(items_type)

    encoder_name = "encode#{items_type_name}s"

    encoder_template(encoder_name, name, items_type_name, items_encoder_name)
  end

  @spec determine_encoder_name(Types.typeDefinition) :: String.t
  defp determine_encoder_name(items_type) do

    if primitive_type?(items_type) do
      determine_primitive_type_encoder!(items_type.type)
    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        "encodeRoot"
      else
        "encode#{upcase_first items_type_name}"
      end
    end
  end

end
