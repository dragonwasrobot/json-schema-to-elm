defmodule JS2E.Printer.PrimitivePrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Logger
  alias JS2E.Printer.PrinterResult
  alias JsonSchema.Types
  alias Types.{PrimitiveType, SchemaDefinition}

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %PrimitiveType{name: _name, path: _path, type: _type},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %PrimitiveType{name: _name, path: _path, type: _type},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %PrimitiveType{name: _name, path: _path, type: _type},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %PrimitiveType{name: _name, path: _path, type: _type},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end
end
