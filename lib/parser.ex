defmodule JS2E.Parser do
  @moduledoc ~S"""
  Parses JSON schema files into an intermediate representation to be used for
  e.g. printing elm decoders.
  """

  require Logger
  alias JS2E.{Types, RootParser}

  @spec parse_schema_files([String.t], String.t)
  :: {:ok, Types.schemaDictionary} | {:error, [String.t]}
  def parse_schema_files(schema_paths, module_name) do

    Enum.reduce_while(schema_paths, {:ok, %{}},
      fn (schema_path, {:ok, schema_dict}) ->

        case parse_schema_file(schema_path, module_name) do
          {:ok, parsed_schema} ->
            {:cont, {:ok, Map.merge(parsed_schema, schema_dict)}}

          {:error, error} ->
            schema_error = "('#{schema_path}'): #{error}"
            {:halt, {:error, schema_error}}
        end
      end)
  end

  @spec parse_schema_file(String.t, String.t)
  :: {:ok, Types.schemaDictionary} | {:error, [String.t]}
  def parse_schema_file(json_schema_path, module_name) do
    json_schema_path
    |> File.read!
    |> Poison.decode!
    |> RootParser.parse_schema(module_name)
  end

end
