defmodule JS2E.Printer.TypeReferencePrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
  A printer for printing a type reference decoder.
  """

  require Logger
  alias JS2E.Printer.PrinterResult
  alias JS2E.Types
  alias JS2E.Types.{TypeReference, SchemaDefinition}

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %TypeReference{name: _name, path: _path},
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
        %TypeReference{name: _name, path: _path},
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
        %TypeReference{name: _name, path: _path},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    PrinterResult.new("")
  end
end
