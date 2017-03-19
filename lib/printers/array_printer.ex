defmodule JS2E.Printers.ArrayPrinter do
  @moduledoc """
  A printer for printing an 'array' type decoder.
  """

  require Logger
  alias JS2E.{Printer, TypePath, Types}
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
      |> TypePath.to_string
      |> Printer.resolve_type(type_dict, schema_dict)

    items_decoder_name = determine_decoder_name(items_type)
    items_type_name = determine_type_name(items_type)

    decoder_name = Util.downcase_first "#{name}Decoder"
    indent = Util.indent()

    """
    #{decoder_name} : Decoder (List #{items_type_name})
    #{decoder_name} =
    #{indent}list #{items_decoder_name}
    """
  end

  @spec determine_decoder_name(Types.typeDefinition) :: String.t
  defp determine_decoder_name(items_type) do

    if items_type.__struct__ == PrimitiveType do
      items_type_value = items_type.type

      cond do
        items_type_value == "integer" ->
          "int"

        items_type_value == "number" ->
          "float"

        true ->
          Util.downcase_first items_type_value
      end

    else
      "#{items_type.name}Decoder"
    end
  end

  @spec determine_type_name(Types.typeDefinition) :: String.t
  defp determine_type_name(items_type) do

    if items_type.__struct__ == PrimitiveType do
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
      Util.upcase_first items_type.name
    end
  end

end
