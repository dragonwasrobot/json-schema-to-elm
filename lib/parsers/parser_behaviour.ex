defmodule JS2E.Parsers.ParserBehaviour do
  @moduledoc ~S"""
  Describes the functions needed to implement a parser for a JSON schema node.
  """

  @callback type?(map) :: boolean

  @callback parse(map, URI.t, URI.t | nil, TypePath.t, String.t)
  :: Types.typeDictionary
end
