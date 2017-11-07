defmodule JS2E.Printers.ErrorUtil do
  @moduledoc ~S"""
  Contains helper functions for reporting printer errors.
  """

  alias JS2E.{Types, TypePath}
  alias JS2E.Printers.{PrinterError}

  @spec unresolved_reference(Types.typeIdentifier) :: PrinterError.t
  def unresolved_reference(identifier) do
    error_msg = "Could not resolve identifier: '#{identifier}'"
    PrinterError.new("", :unresolved_reference, error_msg)
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

  @spec pretty_print_error(PrinterError.t) :: String.t
  def pretty_print_error(%PrinterError{identifier: identifier,
                                      error_type: error_type,
                                      message: message}) do
    printed_id = pretty_identifier(identifier)
    printed_error_type = pretty_error_type(error_type)
    "[error](#{printed_id}) - #{printed_error_type}: #{message}"
  end

  @doc ~S"""
  Pretty prints an identifier.

  ## Examples

      iex> pretty_identifier(JS2E.TypePath.from_string("#/definitions/foo"))
      "#/definitions/foo"

      iex> pretty_identifier(URI.parse("http://www.example.com/root.json#bar"))
      "http://www.example.com/root.json#bar"

      iex> pretty_identifier("#qux")
      "#qux"

  """
  @spec pretty_identifier(Types.typeIdentifier) :: String.t
  def pretty_identifier(identifier) do
    cond do
      TypePath.type_path?(identifier) ->
        TypePath.to_string(identifier)

      is_map(identifier) ->
        URI.to_string(identifier)

      identifier ->
        identifier
    end
  end

  @doc ~S"""
  Pretty prints an error type.

  ## Examples

      iex> pretty_error_type(:dangling_reference)
      "Dangling reference"

  """
  @spec pretty_error_type(PrinterError.error_type) :: String.t
  def pretty_error_type(error_type) do
    error_type
    |> to_string
    |> String.capitalize
    |> String.replace("_", " ")
  end

end
