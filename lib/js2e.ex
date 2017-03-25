defmodule JS2E do
  @moduledoc ~S"""
  Parses JSON schemas and prints Elm types and decoders.
  """

  require Logger
  alias JS2E.{Parser, Printer, Types}

  @spec generate([String.t], String.t) :: :ok | {:error, atom}
  def generate(json_schema_paths, module_name) do

    schema_dict = Parser.parse_schema_files(json_schema_paths)
    printed_decoders = Printer.print_schemas(schema_dict, module_name)

    printed_decoders
    |> Enum.each(fn{file_path, file_content} ->
      {:ok, file} = File.open file_path, [:write]
      IO.binwrite file, file_content
      File.close file
      Logger.info "Created file: #{file_path}"
    end)
  end

end
