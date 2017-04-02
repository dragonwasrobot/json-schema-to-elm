defmodule JS2E.Printers.ArrayPrinter do
  @moduledoc """
  A printer for printing an 'array' type decoder.
  """

  require Logger
  alias JS2E.{Printer, Types}
  alias JS2E.Printers.Util
  alias JS2E.Types.ArrayType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%ArrayType{name: _name,
                            path: _path,
                            items: _items_path}, _type_dict, _schema_dict) do
    ""
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%ArrayType{name: name,
                               path: _path,
                               items: items_path}, type_dict, schema_dict) do

    items_type =
      items_path
      |> Printer.resolve_type(type_dict, schema_dict)

    items_type_name = determine_type_name(items_type)
    items_decoder_name = determine_decoder_name(items_type)

    decoder_name = Util.downcase_first "#{name}Decoder"
    indent = Util.indent()

  """
  #{decoder_name} : Decoder (List #{items_type_name})
  #{decoder_name} =
  #{indent}Decode.list #{items_decoder_name}
  """
  end

  @spec determine_decoder_name(Types.typeDefinition) :: String.t
  defp determine_decoder_name(items_type) do

    if Util.get_string_name(items_type) == "PrimitiveType" do
      items_type_value = items_type.type

      cond do
        items_type_value == "integer" ->
          "Decode.int"

        items_type_value == "number" ->
          "Decode.float"

        true ->
          "Decode.#{Util.downcase_first items_type_value}"
      end

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

    if Util.get_string_name(items_type) == "PrimitiveType" do
      items_type_value = items_type.type

      cond do
        items_type_value == "integer" ->
          "Int"

        items_type_value == "number" ->
          "Float"

        true ->
          Util.upcase_first items_type_value
      end

    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        "Root"
      else
        Util.upcase_first items_type_name
      end

    end
  end

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%ArrayType{name: name,
                               path: _path,
                               items: items_path}, type_dict, schema_dict) do

    items_type =
      items_path
      |> Printer.resolve_type(type_dict, schema_dict)

    items_type_name = determine_type_name(items_type)
    items_encoder_name = determine_encoder_name(items_type)

    encoder_name = "encode#{items_type_name}s"
    indent = Util.indent()

    """
    #{encoder_name} : List #{items_type_name} -> Value
    #{encoder_name} #{name} =
    #{indent}Encode.list <| List.map #{items_encoder_name} <| #{name}
    """
  end

  @spec determine_encoder_name(Types.typeDefinition) :: String.t
  defp determine_encoder_name(items_type) do

    if Util.get_string_name(items_type) == "PrimitiveType" do
      items_type_value = items_type.type

      cond do
        items_type_value == "integer" ->
          "Encode.int"

        items_type_value == "number" ->
          "Encode.float"

        true ->
          "Encode.#{Util.downcase_first items_type_value}"
      end

    else
      items_type_name = items_type.name

      if items_type_name == "#" do
        "encodeRoot"
      else
        "encode#{Util.upcase_first items_type_name}"
      end
    end
  end

end
