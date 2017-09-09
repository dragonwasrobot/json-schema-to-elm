defmodule JS2E.Printers.PrinterBehaviour do
  @moduledoc ~S"""
  Describes the functions needed to implement a printer of a JSON schema node.
  """

  @callback print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t

  @callback print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t

  @callback print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t

end
