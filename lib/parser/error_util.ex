defmodule JS2E.Parser.ErrorUtil do
  @moduledoc ~S"""
  Contains helper functions for reporting parser errors.
  """

  alias JS2E.{Types, TypePath}
  alias JS2E.Parser.ParserError

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
  @spec get_type(any) :: String.t()
  def get_type(value) when is_list(value), do: "list"
  def get_type(value) when is_map(value), do: "object"
  def get_type(value) when is_binary(value), do: "string"
  def get_type(value) when is_boolean(value), do: "boolean"
  def get_type(value) when is_float(value), do: "float"
  def get_type(value) when is_integer(value), do: "integer"
  def get_type(value) when is_nil(value), do: "null"
  def get_type(_value), do: "unknown"

  @spec unsupported_schema_version(String.t(), [String.t()]) :: ParserError.t()
  def unsupported_schema_version(supplied_value, supported_versions) do
    root_path = TypePath.from_string("#")
    stringified_value = sanitize_value(supplied_value)

    error_msg = """
    Unsupported JSON schema version found at '#'.

        "$schema": #{stringified_value}
                   #{error_markings(stringified_value)}

    Was expecting one of the following types:

        #{inspect(supported_versions)}

    Hint: See the specification section 7. "The '$schema' keyword"
    <http://json-schema.org/latest/json-schema-core.html#rfc.section.7>
    """

    ParserError.new(root_path, :unsupported_schema_version, error_msg)
  end

  @spec missing_property(Types.typeIdentifier(), String.t()) :: ParserError.t()
  def missing_property(identifier, property) do
    full_identifier = print_identifier(identifier)

    error_msg = """
    Could not find property '#{property}' at '#{full_identifier}'
    """

    ParserError.new(identifier, :missing_property, error_msg)
  end

  @spec invalid_type(Types.typeIdentifier(), String.t(), String.t(), String.t()) ::
          ParserError.t()
  def invalid_type(identifier, property, expected_type, actual_value) do
    actual_type = get_type(actual_value)
    stringified_value = sanitize_value(actual_value)

    full_identifier = print_identifier(identifier)

    error_msg = """
    Expected value of property '#{property}' at '#{full_identifier}'
    to be of type '#{expected_type}' but found a value of type '#{actual_type}'

        "#{property}": #{stringified_value}
                       #{error_markings(stringified_value)}

    """

    ParserError.new(identifier, :type_mismatch, error_msg)
  end

  @spec schema_name_collision(Types.typeIdentifier()) :: ParserError.t()
  def schema_name_collision(identifier) do
    full_identifier = print_identifier(identifier)

    error_msg = """
    Found more than one schema with id: '#{full_identifier}'
    """

    ParserError.new(identifier, :name_collision, error_msg)
  end

  @spec name_collision(Types.typeIdentifier()) :: ParserError.t()
  def name_collision(identifier) do
    full_identifier = print_identifier(identifier)

    error_msg = """
    Found more than one property with identifier '#{full_identifier}'
    """

    ParserError.new(identifier, :name_collision, error_msg)
  end

  @spec invalid_uri(Types.typeIdentifier(), String.t(), String.t()) ::
          ParserError.t()
  def invalid_uri(identifier, property, actual) do
    full_identifier = print_identifier(identifier)
    stringified_value = sanitize_value(actual)

    error_msg = """
    Could not parse property '#{property}' at '#{full_identifier}' into a valid URI.

        "id": #{stringified_value}
              #{error_markings(stringified_value)}

    Hint: See URI specification section 3. "Syntax Components"
    <https://tools.ietf.org/html/rfc3986#section-3>
    """

    ParserError.new(identifier, :invalid_uri, error_msg)
  end

  @spec unknown_node_type(Types.typeIdentifier(), String.t(), Types.node()) ::
          ParserError.t()
  def unknown_node_type(identifier, name, schema_node) do
    full_identifier =
      identifier
      |> TypePath.add_child(name)
      |> TypePath.to_string()

    stringified_value = sanitize_value(schema_node["type"])

    error_msg = """
    The value of "type" at '#{full_identifier}' did not match a known node type

        "type": #{stringified_value}
                #{error_markings(stringified_value)}

    Was expecting one of the following types

        ["null", "boolean", "object", "array", "number", "integer", "string"]

    Hint: See the specification section 6.25. "Validation keywords - type"
    <http://json-schema.org/latest/json-schema-validation.html#rfc.section.6.25>
    """

    ParserError.new(full_identifier, :unknown_node_type, error_msg)
  end

  @spec print_identifier(Types.typeIdentifier()) :: String.t()
  defp print_identifier(identifier) do
    if TypePath.type_path?(identifier) do
      TypePath.to_string(identifier)
    else
      to_string(identifier)
    end
  end

  @spec sanitize_value(any) :: String.t()
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

  @spec error_markings(String.t()) :: String.t()
  defp error_markings(value) do
    red(String.duplicate("^", String.length(value)))
  end

  @spec red(String.t()) :: list
  defp red(str) do
    IO.ANSI.format([:red, str])
  end
end
