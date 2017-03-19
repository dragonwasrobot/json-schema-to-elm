defmodule JS2E.Printers.PrimitivePrinter do
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Types.PrimitiveType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%PrimitiveType{name: _name,
                                path: _path,
                                type: _type}, _type_dict, _schema_dict) do
    ""
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%PrimitiveType{name: _name,
                                   path: _path,
                                   type: _type}, _type_dict, _schema_dict) do
    ""
  end

end
