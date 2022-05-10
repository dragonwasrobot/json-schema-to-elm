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
      default value is 'Data'.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Parser.{ParserError, ParserWarning}
  alias Printer.PrinterError

  @output_location Application.compile_env(:js2e, :output_location)

  @spec main([String.t()]) :: :ok
  def main(args) do
    {options, paths, errors} = OptionParser.parse(args, switches: [module_name: :string])

    if Enum.empty?(paths) == true do
      IO.puts(@moduledoc)
      exit(:normal)
    end

    if length(errors) > 0 do
      print_error("Error: Found one or more errors in the supplied options")
      exit({:unknown_arguments, errors})
    end

    files = resolve_all_paths(paths)

    if Enum.empty?(files) == true do
      print_error("Error: Could not find any JSON files in path: #{inspect(paths)}")

      exit(:no_files)
    end

    output_path = create_output_dir(options)
    generate(files, output_path)
  end

  @spec resolve_all_paths([String.t()]) :: [Path.t()]
  defp resolve_all_paths(paths) do
    paths
    |> Enum.filter(&File.exists?/1)
    |> Enum.reduce([], fn filename, files ->
      cond do
        File.dir?(filename) ->
          walk_directory(filename) ++ files

        String.ends_with?(filename, ".json") ->
          [filename | files]

        true ->
          files
      end
    end)
  end

  @spec walk_directory(String.t()) :: [String.t()]
  defp walk_directory(dir) do
    dir
    |> File.ls!()
    |> Enum.reduce([], fn file, files ->
      filename = "#{dir}/#{file}"

      cond do
        File.dir?(filename) ->
          walk_directory(filename) ++ files

        String.ends_with?(file, ".json") ->
          [filename | files]

        true ->
          files
      end
    end)
  end

  @spec create_output_dir(list) :: String.t()
  defp create_output_dir(options) do
    module_name =
      if Keyword.has_key?(options, :module_name) do
        Keyword.get(options, :module_name)
      else
        "Data"
      end

    "#{@output_location}/src"
    |> Path.join(module_name)
    |> String.replace(".", "/")
    |> File.mkdir_p!()

    "#{@output_location}/tests"
    |> Path.join(module_name)
    |> String.replace(".", "/")
    |> File.mkdir_p!()

    module_name
  end

  @spec generate([String.t()], String.t()) :: :ok
  def generate(schema_paths, module_name) do
    Logger.info("Parsing JSON schema files!")
    parser_result = JsonSchema.parse_schema_files(schema_paths)

    pretty_parser_warnings(parser_result.warnings)

    if length(parser_result.errors) > 0 do
      pretty_parser_errors(parser_result.errors)
    else
      Logger.info("Converting to Elm code!")

      printer_result = Printer.print_schemas(parser_result.schema_dict, module_name)

      tests_printer_result = Printer.print_schemas_tests(parser_result.schema_dict, module_name)

      cond do
        length(printer_result.errors) > 0 ->
          pretty_printer_errors(printer_result.errors)

        length(tests_printer_result.errors) > 0 ->
          pretty_printer_errors(tests_printer_result.errors)

        true ->
          Logger.info("Printing Elm code to file(s)!")

          file_dict = printer_result.file_dict

          Enum.each(file_dict, fn {file_path, file_content} ->
            normalized_file_path =
              String.replace(
                file_path,
                module_name,
                String.replace(module_name, ".", "/")
              )

            Logger.debug(fn -> "Writing file '#{normalized_file_path}'" end)
            {:ok, file} = File.open(normalized_file_path, [:write])
            IO.binwrite(file, file_content)
            File.close(file)
            Logger.info("Created file '#{normalized_file_path}'")
          end)

          tests_file_dict = tests_printer_result.file_dict

          Enum.each(tests_file_dict, fn {file_path, file_content} ->
            normalized_file_path =
              String.replace(
                file_path,
                module_name,
                String.replace(module_name, ".", "/")
              )

            Logger.debug("Writing file '#{normalized_file_path}'")
            {:ok, file} = File.open(normalized_file_path, [:write])
            IO.binwrite(file, file_content)
            File.close(file)
            Logger.info("Created file '#{normalized_file_path}'")
          end)

          IO.puts("""
          Elm types, decoders, encoders and tests
          written to '#{@output_location}'.

          Go to '#{@output_location}' and run

              $ npm install

          followed by

              $ npm test

          in order to run 'elm-test' test suite
          on the generated Elm source code.
          """)
      end
    end
  end

  @spec pretty_parser_warnings([{Path.t(), [ParserWarning.t()]}]) :: :ok
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
            |> String.downcase()

          padding =
            String.duplicate(
              "-",
              max(
                0,
                74 - String.length(pretty_warning_type) -
                  String.length(file_path)
              )
            )

          warnings
          |> Enum.each(fn warning ->
            print_header("--- #{pretty_warning_type} #{padding} #{file_path}\n")
            IO.puts(warning.message)
          end)
        end)
      end
    end)

    :ok
  end

  @spec pretty_parser_errors([{Path.t(), [ParserError.t()]}]) :: :ok
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
            |> String.upcase()

          padding =
            String.duplicate(
              "-",
              max(
                0,
                74 - String.length(pretty_error_type) - String.length(file_path)
              )
            )

          errors
          |> Enum.each(fn error ->
            print_header("--- #{pretty_error_type} #{padding} #{file_path}\n")
            IO.puts(error.message)
          end)
        end)
      end
    end)

    :ok
  end

  @spec pretty_printer_errors([PrinterError.t()]) :: :ok
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
            |> String.upcase()

          padding =
            String.duplicate(
              "-",
              max(
                0,
                74 - String.length(pretty_error_type) - String.length(file_path)
              )
            )

          errors
          |> Enum.each(fn error ->
            print_header("--- #{pretty_error_type} #{padding} #{file_path}\n")
            IO.puts(error.message)
          end)
        end)
      end
    end)

    :ok
  end

  defp print_error(str) do
    IO.puts(IO.ANSI.format([:cyan, str]))
  end

  defp print_header(str) do
    IO.puts(IO.ANSI.format([:cyan, str]))
  end

  defp warning_header do
    header = String.duplicate("^", 35) <> " WARNINGS " <> String.duplicate("^", 35)

    IO.puts(IO.ANSI.format([:yellow, header]))
  end
end
