defmodule Mix.Tasks.Elm.Gen do

  @shortdoc "Generate Elm code from JSON schemas"
  @moduledoc ~S"""
  Transforms one or more JSON schema files into their corresponding
  Elm types and JSON decoders.

  Expects a PATH to one or more JSON schema files from which to generate
  Elm code.

      mix elm.gen PATH [--module-name NAME]

  The JSON schema(s) at the given PATH will be converted to Elm types
  and JSON decoders.

  ## Options

    * `--module-name` - the module name prefix for the printed Elm modules \
      default value is 'Domain'.
  """

  use Mix.Task
  require Logger
  alias JS2E

  defmodule Options do
    @moduledoc ~S"""
    Represents the possible options accepted by the `mix elm.gen` command.
    """
    defstruct [
      module_name: nil
    ]
  end

  @spec run([String.t]) :: :ok
  def run(args) do
    Logger.debug "Arguments: #{inspect args}"

    {options, paths, errors} =
      OptionParser.parse(args, switches: [module_name: :string])

    if length(errors) > 0 do
      Logger.error "Found one or more errors in the supplied options"
      exit({:unknown_arguments, errors})
    end

    files = resolve_all_paths(paths)
    Logger.debug "Files: #{inspect files}"

    if length(files) == 0 do
      Logger.warn "Could not find any JSON files in path: #{inspect paths}"
      exit(:no_files)
    end

    output_path = create_output_dir(options)
    JS2E.generate(files, output_path)
  end

  @spec resolve_all_paths([String.t]) :: [String.t]
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
    |> Path.join("Decoders")
    |> File.mkdir_p!()

    output_path
  end

end
