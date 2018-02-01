defmodule JS2E.Printers.ErrorUtil do
  @moduledoc ~S"""
  Contains helper functions for reporting printer errors.
  """

  alias JS2E.{Types, TypePath}
  alias JS2E.Printers.{PrinterError}

  @spec unresolved_reference(
    Types.typeIdentifier,
    TypePath.t
  ) :: PrinterError.t
  def unresolved_reference(identifier, parent) do

    printed_path = TypePath.to_string(parent)
    stringified_value = sanitize_value(identifier)

    error_msg =
    """

    The following reference at `#{printed_path}` could not be resolved

        "$ref": #{stringified_value}
                #{error_markings(stringified_value)}


    Hint: See the specification section 9. "Base URI and dereferencing"
    <http://json-schema.org/latest/json-schema-core.html#rfc.section.9>
    """

    PrinterError.new(parent, :unresolved_reference, error_msg)
  end

  @spec unknown_type(String.t) :: PrinterError.t
  def unknown_type(type_name) do
    error_msg = "Could not find printer for type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_type, error_msg)
  end

  @spec unknown_enum_type(String.t) :: PrinterError.t
  def unknown_enum_type(type_name) do
    error_msg = "Unknown or unsupported enum type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_enum_type, error_msg)
  end

  @spec unknown_primitive_type(String.t) :: PrinterError.t
  def unknown_primitive_type(type_name) do
    error_msg = "Unknown or unsupported primitive type: '#{type_name}'"
    PrinterError.new(type_name, :unknown_primitive_type, error_msg)
  end

  @spec name_collision(String.t) :: ParserError.t
  def name_collision(file_name) do
    error_msg = "Found more than one schema with file: '#{file_name}'"
    PrinterError.new(file_name, :name_collision, error_msg)
  end

  @spec print_identifier(Types.typeIdentifier) :: String.t
  defp print_identifier(identifier) do

    if TypePath.type_path?(identifier) do
      TypePath.to_string(identifier)
    else
      to_string(identifier)
    end
  end

  @spec sanitize_value(any) :: String.t
  defp sanitize_value(raw_value) do
    cond do
      is_map(raw_value) ->
        Poison.encode!(raw_value)

      TypePath.type_path?(raw_value) ->
        TypePath.to_string(raw_value)

      true ->
        inspect(raw_value)
    end
  end

  @spec error_markings(String.t) :: String.t
  defp error_markings(value) do
    red(String.duplicate("^", String.length(value)))
  end

  @spec red(String.t) :: list
  defp red(str) do
    IO.ANSI.format([:red, str])
  end

end
