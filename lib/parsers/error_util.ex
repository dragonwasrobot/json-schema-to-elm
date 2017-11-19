defmodule JS2E.Parsers.ErrorUtil do
  @moduledoc ~S"""
  Contains helper functions for reporting parser errors.
  """

  alias JS2E.{Types, TypePath}
  alias JS2E.Parsers.ParserError

  @doc ~S"""
  Returns the name of the type of the given value.

  ## Examples

  iex> get_type([1,2,3])
  "list"

  iex> get_type(%{"type" => "string"})
  "object"

  iex> get_type("name")
  "string"

  iex> get_type(42)
  "integer"

  """
  @spec get_type(any) :: String.t
  def get_type(value) when is_list(value), do: "list"
  def get_type(value) when is_map(value), do: "object"
  def get_type(value) when is_binary(value), do: "string"
  def get_type(value) when is_boolean(value), do: "boolean"
  def get_type(value) when is_float(value), do: "float"
  def get_type(value) when is_integer(value), do: "integer"
  def get_type(value) when is_nil(value), do: "null"
  def get_type(_value), do: "unknown"

  @spec unsupported_schema_version(String.t, String.t) :: ParserError.t
  def unsupported_schema_version(expected, actual) do

    root_path = TypePath.from_string("#")
    error_msg = "Unsupported JSON schema version found in '$schema': " <>
      "'#{actual}'. Supported versions are: '#{expected}'"

    ParserError.new(root_path, :unsupported_schema_version, error_msg)
  end

  @spec missing_property(Types.typeIdentifier, String.t)
  :: ParserError.t
  def missing_property(identifier, property) do
    error_msg = "Missing property: '#{property}' for schema: '#{identifier}'"
    ParserError.new(identifier, :missing_property, error_msg)
  end

  @spec invalid_type(Types.typeIdentifier, String.t, String.t, String.t)
  :: ParserError.t
  def invalid_type(identifier, property, expected, actual) do
    error_msg = "Expected value of property: '#{property}' " <>
      "to be of type: '#{expected}' " <>
      "but was of type: '#{actual}'."
    ParserError.new(identifier, :type_mismatch, error_msg)
  end

  @spec schema_name_collision(Types.typeIdentifier) :: ParserError.t
  def schema_name_collision(identifier) do
    error_msg =
    """
    Found more than one schema with id: '#{identifier}'
    """
    ParserError.new(identifier, :name_collision, error_msg)
  end

  @spec name_collision(Types.typeIdentifier) :: ParserError.t
  def name_collision(identifier) do
    error_msg = "Found more than one property with identifier: '#{identifier}'"
    ParserError.new(identifier, :name_collision, error_msg)
  end

  @spec invalid_uri(Types.typeIdentifier, String.t, String.t) :: ParserError.t
  def invalid_uri(identifier, property, actual) do
    error_msg = "Could not parse property '#{property}' with value " <>
      "'#{actual}' into a valid URI."
    ParserError.new(identifier, :invalid_uri, error_msg)
  end

  @spec unknown_node_type(Types.typeIdentifier, String.t, Types.node)
  :: ParserError.t
  def unknown_node_type(identifier, name, schema_node) do

    full_identifier =
      identifier
      |> TypePath.add_child(name)
      |> TypePath.to_string

    json_node = Poison.encode!(schema_node)
    type_value = schema_node["type"]
    error_msg =
    """
    The value of "type" at path: '#{full_identifier}' did not match a known node type.

        "type": "#{type_value}"
                #{String.duplicate("^", String.length(type_value) + 2)}

    Was expecting one of the following types:

    ["null", "boolean", "object", "array", "number", "integer", "string"]

    Hint: See the specification section 6.25. "Validation keywords - type"
    <http://json-schema.org/latest/json-schema-validation.html#rfc.section.6.25>
    """

 "Could not recognize node type: " <>
      "'#{json_node}' as its type could not be recognized."
    ParserError.new(full_identifier, :unknown_node_type, error_msg)
  end

  @spec pretty_print_error(ParserError.t) :: String.t
  def pretty_print_error(%ParserError{identifier: identifier,
                                      error_type: error_type,
                                      message: message}) do
    printed_id = pretty_identifier(identifier)
    printed_error_type = pretty_error_type(error_type)
    "(#{printed_id}) - #{printed_error_type}: #{message}"
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
  @spec pretty_error_type(ParserError.error_type) :: String.t
  def pretty_error_type(error_type) do
    error_type
    |> to_string
    |> String.capitalize
    |> String.replace("_", " ")
  end

end
