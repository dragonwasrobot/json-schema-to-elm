defmodule JS2E.Printers.TypeReferencePrinter do
  @moduledoc """
  A printer for printing a type reference decoder.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Types.TypeReference

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%TypeReference{name: _name,
                                path: _path}, _type_dict, _schema_dict) do
    ""
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%TypeReference{name: _name,
                                   path: _path}, _type_dict, _schema_dict) do
    ""
  end

end
