defmodule JS2E.Parser do
  @moduledoc ~S"""
  Parses JSON schema files into an intermediate representation to be used for
  e.g. printing elm decoders.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Parser.{RootParser, SchemaResult, ErrorUtil}
  alias JS2E.Printers.Util

  @spec parse_schema_files([Path.t()]) :: SchemaResult.t()
  def parse_schema_files(schema_paths) do
    init_schema_result = SchemaResult.new()

    schema_paths
    |> Enum.reduce(init_schema_result, fn schema_path, acc ->
      schema_path
      |> File.read!()
      |> Poison.decode!()
      |> RootParser.parse_schema(schema_path)
      |> SchemaResult.merge(acc)
    end)
  end
end
