defmodule JS2E.Printer.ErrorUtil do
  @moduledoc """
  Contains helper functions for reporting printer errors.
  """

  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.PrinterError

  @spec unresolved_reference(
          Types.typeIdentifier(),
          URI.t()
        ) :: PrinterError.t()
  def unresolved_reference(identifier, parent) do
    printed_path = to_string(parent)
    stringified_value = sanitize_value(identifier)

    error_msg = """

    The following reference at `#{printed_path}` could not be resolved

        "$ref": #{stringified_value}
                #{error_markings(stringified_value)}

    Be aware that newer versions of JSON schema uses "$id" rather than "id" when
    specifying the id of a JSON schema or subschema.

    Hint: See the specification section 8. "Base URI and Dereferencing"
    <https://datatracker.ietf.org/doc/html/draft-handrews-json-schema-01#section-8>
    """

    PrinterError.new(parent, :unresolved_reference, error_msg)
  end

  @spec unknown_type(String.t()) :: PrinterError.t()
  def unknown_type(type_name) do
    error_msg = "Could not find printer for type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_type, error_msg)
  end

  @spec unexpected_type(Types.typeIdentifier(), String.t()) :: PrinterError.t()
  def unexpected_type(identifier, error_msg) do
    PrinterError.new(identifier, :unexpected_type, error_msg)
  end

  @spec unknown_enum_type(String.t()) :: PrinterError.t()
  def unknown_enum_type(type_name) do
    error_msg = "Unknown or unsupported enum type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_enum_type, error_msg)
  end

  @spec unknown_primitive_type(String.t()) :: PrinterError.t()
  def unknown_primitive_type(type_name) do
    error_msg = "Unknown or unsupported primitive type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_primitive_type, error_msg)
  end

  @spec name_collision(String.t()) :: PrinterError.t()
  def name_collision(file_name) do
    error_msg = "Found more than one schema with file: '#{file_name}'"
    PrinterError.new(file_name, :name_collision, error_msg)
  end

  @spec sanitize_value(any) :: String.t()
  defp sanitize_value(raw_value) do
    cond do
      is_map(raw_value) and raw_value.__struct__ == URI ->
        URI.to_string(raw_value)

      is_map(raw_value) ->
        "#{inspect(raw_value)}"

      true ->
        inspect(raw_value)
    end
  end

  @spec error_markings(String.t()) :: [String.t()]
  defp error_markings(value) do
    red(String.duplicate("^", String.length(value)))
  end

  @spec red(String.t()) :: [String.t()]
  defp red(str) do
    IO.ANSI.format([:red, str])
  end
end
