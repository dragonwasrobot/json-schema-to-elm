defmodule JS2E do
  @moduledoc ~S"""
  Transforms one or more JSON schema files into their corresponding
  Elm types and JSON decoders.

  Expects a PATH to one or more JSON schema files from which to generate
  Elm code.

      js2e PATH [--module-name NAME]

  The JSON schema(s) at the given PATH will be converted to Elm types
  and JSON decoders.

  ## Options

      * `--module-name` - the module name prefix for the printed Elm modules \
      default value is 'Domain'.
  """

  require Logger
  alias JS2E.Parser
  alias Parser.ParserWarning
  alias Parser.ParserError
  alias JS2E.Printer
  alias JS2E.Printer.PrinterError

  @spec main([String.t]) :: :ok
  def main(args) do

    {options, paths, errors} =
      OptionParser.parse(args, switches: [module_name: :string])

    if length(paths) == 0 do
      IO.puts @moduledoc
      exit(:normal)
    end

    if length(errors) > 0 do
      print_error("Error: Found one or more errors in the supplied options")
      exit({:unknown_arguments, errors})
    end

    files = resolve_all_paths(paths)

    if length(files) == 0 do
      print_error("Error: Could not find any " <>
        "JSON files in path: #{inspect paths}")
      exit(:no_files)
    end

    output_path = create_output_dir(options)
    JS2E.generate(files, output_path)
  end

  @spec resolve_all_paths([String.t]) :: [Path.t]
  defp resolve_all_paths(paths) do
    paths
    |> Enum.filter(&File.exists?/1)
    |> Enum.reduce([], fn (filename, files) ->
      cond do
        File.dir? filename ->
          walk_directory(filename) ++ files

        String.ends_with?(filename, ".json") ->
          [filename | files]

        true ->
          files
      end
    end)
  end

  @spec walk_directory(String.t) :: [String.t]
  defp walk_directory(dir) do
    dir
    |> File.ls!
    |> Enum.reduce([], fn file, files ->
      filename = "#{dir}/#{file}"

      cond do
        File.dir? filename ->
          walk_directory(filename) ++ files

        String.ends_with?(file, ".json") ->
          [filename | files]

        true ->
          files
      end
    end)
  end

  @spec create_output_dir(list) :: String.t
  defp create_output_dir(options) do

    output_path = if Keyword.has_key?(options, :module_name) do
      Keyword.get(options, :module_name)
    else
      "Domain"
    end

    output_path
    |> File.mkdir_p!()

    output_path
  end

  @spec generate([String.t], String.t) :: :ok
  def generate(schema_paths, module_name) do

    Logger.info "Parsing JSON schema files!"
    parser_result = Parser.parse_schema_files(schema_paths)
    pretty_parser_warnings(parser_result.warnings)

    if length(parser_result.errors) > 0 do
      pretty_parser_errors(parser_result.errors)

    else
      Logger.info "Converting to Elm code!"
      printer_result = Printer.print_schemas(parser_result.schema_dict, module_name)

      if length(printer_result.errors) > 0 do
        pretty_printer_errors(printer_result.errors)

      else
        Logger.info "Printing Elm code to file(s)!"

        file_dict = printer_result.file_dict
        Enum.each(file_dict, fn {file_path, file_content} ->
          {:ok, file} = File.open file_path, [:write]
          IO.binwrite file, file_content
          File.close file
          Logger.info "Created file '#{file_path}'"
        end)
      end
    end
  end

  @spec pretty_parser_warnings([ParserWarning.t()]) :: :ok
  defp pretty_parser_warnings(warnings) do
    warnings
    |> Enum.each(fn {file_path, warnings} ->
      if length(warnings) > 0 do

        warning_header()

        warnings
        |> Enum.group_by(fn warning -> warning.warning_type end)
        |> Enum.each(fn {warning_type, warnings} ->
          pretty_warning_type =
            warning_type
            |> to_string
            |> String.replace("_", " ")
            |> String.downcase

          padding = String.duplicate("-",
            74 - String.length(pretty_warning_type) - String.length(file_path))

          warnings
          |> Enum.each(fn warning ->
            print_header("--- #{pretty_warning_type} #{padding} #{file_path}\n")
            IO.puts warning.message
          end)
        end)

      end
    end)
    :ok
  end

  @spec pretty_parser_errors([ParserError.t()]) :: :ok
  defp pretty_parser_errors(errors) do
    errors
    |> Enum.each(fn {file_path, errors} ->
      if length(errors) > 0 do

        errors
        |> Enum.group_by(fn err -> err.error_type end)
        |> Enum.each(fn {error_type, errors} ->
          pretty_error_type =
            error_type
            |> to_string
            |> String.replace("_", " ")
            |> String.upcase

          padding = String.duplicate("-",
            74 - String.length(pretty_error_type) - String.length(file_path))

          errors
          |> Enum.each(fn error ->
            print_header("--- #{pretty_error_type} #{padding} #{file_path}\n")
            IO.puts error.message
          end)
        end)
      end
    end)

    :ok
  end

  @spec pretty_printer_errors([PrinterError.t]) :: :ok
  defp pretty_printer_errors(errors) do

    errors
    |> Enum.each(fn {file_path, errors} ->
      if length(errors) > 0 do

        errors
        |> Enum.group_by(fn err -> err.error_type end)
        |> Enum.each(fn {error_type, errors} ->

          pretty_error_type =
            error_type
            |> to_string
            |> String.replace("_", " ")
            |> String.upcase

          padding = String.duplicate("-",
            74 - String.length(pretty_error_type) - String.length(file_path))

          errors
          |> Enum.each(fn error ->
            print_header("--- #{pretty_error_type} #{padding} #{file_path}\n")
            IO.puts error.message
          end)
        end)

      end
    end)
    :ok
  end

  defp print_error(str) do
    IO.puts IO.ANSI.format([:cyan, str])
  end

  defp print_header(str) do
    IO.puts IO.ANSI.format([:cyan, str])
  end

  defp warning_header do
    header = String.duplicate("^", 35) <>
      " WARNINGS " <>
      String.duplicate("^", 35)

    IO.puts IO.ANSI.format([:yellow, header])
  end

end
