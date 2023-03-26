defmodule JS2E.Printer.PrinterBehaviour do
  @moduledoc """
  Describes the functions needed to implement a printer of a JSON schema node.
  """

  alias JS2E.Printer.PrinterResult
  alias JsonSchema.Types
  alias Types.SchemaDefinition

  @callback print_type(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: PrinterResult.t()

  @callback print_decoder(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: PrinterResult.t()

  @callback print_encoder(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: PrinterResult.t()

  @callback print_fuzzer(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: PrinterResult.t()
end
