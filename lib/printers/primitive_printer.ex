defmodule JS2E.Printers.PrimitivePrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Types.{PrimitiveType, SchemaDefinition}

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_type(%PrimitiveType{name: _name,
                                path: _path,
                                type: _type}, _schema_def, _schema_dict) do
    ""
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_decoder(%PrimitiveType{name: _name,
                                   path: _path,
                                   type: _type}, _schema_def, _schema_dict) do
    ""
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_encoder(%PrimitiveType{name: _name,
                                   path: _path,
                                   type: _type}, _schema_def, _schema_dict) do
    ""
  end

end
