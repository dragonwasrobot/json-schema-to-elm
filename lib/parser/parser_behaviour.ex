defmodule JS2E.Parser.ParserBehaviour do
  @moduledoc ~S"""
  Describes the functions needed to implement a parser for a JSON schema node.
  """

  alias JS2E.{TypePath, Types}
  alias JS2E.Parser.ParserResult

  @callback type?(Types.schemaNode()) :: boolean

  @callback parse(
              Types.schemaNode(),
              URI.t(),
              URI.t() | nil,
              TypePath.t(),
              String.t()
            ) :: ParserResult.t()
end
