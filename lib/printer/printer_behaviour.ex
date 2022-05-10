defmodule JS2E.Printer.PrinterBehaviour do
  @moduledoc """
  Describes the functions needed to implement a printer of a JSON schema node.
  """

  alias JS2E.Printer.Util.{ElmDecoders, ElmEncoders, ElmFuzzers, ElmTypes}
  alias JsonSchema.Types
  alias Types.SchemaDefinition

  @callback print_type(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: ElmTypes.type_definition()

  @callback print_decoder(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: ElmDecoders.decoder_definition()

  @callback print_encoder(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: ElmEncoders.encoder_definition()

  @callback print_fuzzer(
              Types.typeDefinition(),
              SchemaDefinition.t(),
              Types.schemaDictionary(),
              String.t()
            ) :: ElmFuzzers.fuzzer_definition()
end
