defmodule JS2E.Printers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema printers.
  """

  alias JS2E.Types
  alias JS2E.Types.SchemaDefinition

  # Indentation, whitespace and casing - start

  @indent_size 4

  @doc ~S"""
  Returns a chunk of indentation.

  ## Examples

      iex> indent(2)
      "        "

  """
  @spec indent(pos_integer) :: String.t
  def indent(tabs \\ 1) when is_integer(tabs) do
    String.pad_leading("", tabs * @indent_size)
  end

  @doc ~S"""
  Remove excessive newlines of a string.
  """
  @spec trim_newlines(String.t) :: String.t
  def trim_newlines(str) do
    String.trim(str) <> "\n"
  end

  @doc ~S"""
  Upcases the first letter of a string.

  ## Examples

      iex> upcase_first("foobar")
      "Foobar"

  """
  @spec upcase_first(String.t) :: String.t
  def upcase_first(string) when is_binary(string) do
    if String.length(string) > 0 do
      String.upcase(String.at string, 0) <>
        String.slice(string, 1..-1)
    else
      ""
    end
  end

  @doc ~S"""
  Upcases the first letter of a string.

  ## Examples

      iex> downcase_first("Foobar")
      "foobar"

  """
  @spec downcase_first(String.t) :: String.t
  def downcase_first(string) when is_binary(string) do
    if String.length(string) > 0 do
      String.downcase(String.at string, 0) <>
        String.slice(string, 1..-1)
    else
      ""
    end
  end

  # Indentation, whitespace and casing - end

  # Printing types - start

  @spec create_type_name(
    {Types.typeDefinition, SchemaDefinition.t},
    SchemaDefinition.t
  ) :: String.t
  def create_type_name({resolved_type, resolved_schema}, context_schema) do

    type_name = (if primitive_type?(resolved_type) do
      determine_primitive_type!(resolved_type.type)
    else
      resolved_type_name = resolved_type.name
      if resolved_type_name == "#" do
        if resolved_schema.title != nil do
          upcase_first resolved_schema.title
        else
          "Root"
        end
      else
        upcase_first resolved_type_name
      end
    end)

    if resolved_schema.id != context_schema.id do
      qualify_name(type_name, resolved_schema)
    else
      type_name
    end

  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm type equivalent. Raises and error otherwise.

  ## Examples

  iex> determine_primitive_type!("string")
  "String"

  iex> determine_primitive_type!("integer")
  "Int"

  iex> determine_primitive_type!("number")
  "Float"

  iex> determine_primitive_type!("boolean")
  "Bool"

  iex> determine_primitive_type!("array")
  ** (RuntimeError) Unknown or unsupported primitive type: 'array'

  """
  @spec determine_primitive_type!(String.t) :: String.t
  def determine_primitive_type!(type_name) do
    case type_name do
      "string" ->
        "String"

      "integer" ->
        "Int"

      "number" ->
        "Float"

      "boolean" ->
        "Bool"

      _ ->
        raise "Unknown or unsupported primitive type: '#{type_name}'"
    end
  end

  # Printing types - end

  # Printing decoders - start

  @spec create_decoder_name(
    {Types.typeDefinition, SchemaDefinition.t},
    SchemaDefinition.t
  ) :: String.t
  def create_decoder_name({resolved_type, resolved_schema}, context_schema) do

    decoder_name = (if primitive_type?(resolved_type) do
      determine_primitive_type_decoder!(resolved_type.type)
    else
      type_name = resolved_type.name
      if type_name == "#" do
        if resolved_schema.title != nil do
          "#{downcase_first resolved_schema.title}Decoder"
        else
          "rootDecoder"
        end
      else
        "#{type_name}Decoder"
      end
    end)

    if resolved_schema.id != context_schema.id do
      qualify_name(decoder_name, resolved_schema)
    else
      decoder_name
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm decoder equivalent. Raises an error otherwise.

  ## Examples

  iex> determine_primitive_type_decoder!("string")
  "Decode.string"

  iex> determine_primitive_type_decoder!("integer")
  "Decode.int"

  iex> determine_primitive_type_decoder!("number")
  "Decode.float"

  iex> determine_primitive_type_decoder!("boolean")
  "Decode.bool"

  iex> determine_primitive_type_decoder!("array")
  ** (RuntimeError) Unknown or unsupported primitive type: 'array'

  """
  @spec determine_primitive_type_decoder!(String.t) :: String.t
  def determine_primitive_type_decoder!(type_name) do

    case type_name do
      "string" ->
        "Decode.string"

      "integer" ->
        "Decode.int"

      "number" ->
        "Decode.float"

      "boolean" ->
        "Decode.bool"

      _ ->
        raise "Unknown or unsupported primitive type: '#{type_name}'"
    end
  end

  # Printing decoders - end

  # Printing encoders - start

  @doc ~S"""
  Returns the encoder name given a JSON schema type definition.
  """
  @spec create_encoder_name(
    {Types.typeDefinition, SchemaDefinition.t},
    SchemaDefinition.t
  ) :: String.t
  def create_encoder_name({resolved_type, resolved_schema}, context_schema) do

    encoder_name = (if primitive_type?(resolved_type) do
      determine_primitive_type_encoder!(resolved_type.type)
    else
      type_name = resolved_type.name
      if type_name == "#" do
        if resolved_schema.title != nil do
          "encode#{upcase_first resolved_schema.title}"
        else
          "encodeRoot"
        end
      else
        "encode#{upcase_first type_name}"
      end
    end)

    if resolved_schema.id != context_schema.id do
      qualify_name(encoder_name, resolved_schema)
    else
      encoder_name
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  "boolean", and "null" into their Elm encoder equivalent. Raises an error
  otherwise.

  ## Examples

  iex> determine_primitive_type_encoder!("string")
  "Encode.string"

  iex> determine_primitive_type_encoder!("integer")
  "Encode.int"

  iex> determine_primitive_type_encoder!("number")
  "Encode.float"

  iex> determine_primitive_type_encoder!("boolean")
  "Encode.bool"

  iex> determine_primitive_type_encoder!("null")
  "Encode.null"

  iex> determine_primitive_type_encoder!("array")
  ** (RuntimeError) Unknown or unsupported primitive type: 'array'

  """
  @spec determine_primitive_type_encoder!(String.t) :: String.t
  def determine_primitive_type_encoder!(type_name) do

    case type_name do
      "string" ->
        "Encode.string"

      "integer" ->
        "Encode.int"

      "number" ->
        "Encode.float"

      "boolean" ->
        "Encode.bool"

      "null" ->
        "Encode.null"

      _ ->
        raise "Unknown or unsupported primitive type: '#{type_name}'"
    end
  end

  # Printing encoders - end

  # Printing utils - start

  @spec qualify_name(String.t, SchemaDefinition.t) :: String.t
  def qualify_name(type_name, schema_def) do
    if schema_def.title do
      "#{schema_def.module}.#{schema_def.title}.#{type_name}"
    else
      "#{schema_def.module}.#{type_name}"
    end
  end

  @doc ~S"""
  Get the string shortname of the given struct.

  ## Examples

  iex> primitive_type = %JS2E.Types.PrimitiveType{name: "foo",
  ...>                                        path: ["#","foo"],
  ...>                                        type: "string"}
  ...> get_string_name(primitive_type)
  "PrimitiveType"

  """
  @spec get_string_name(struct) :: String.t
  def get_string_name(instance) when is_map(instance) do
    instance.__struct__
    |> to_string
    |> String.split(".")
    |> List.last
  end

  # Printing utils - end

  # Predicate functions - start

  @spec primitive_type?(struct) :: boolean
  def primitive_type?(type) do
    get_string_name(type) == "PrimitiveType"
  end

  @spec enum_type?(struct) :: boolean
  def enum_type?(type) do
    get_string_name(type) == "EnumType"
  end

  @spec one_of_type?(struct) :: boolean
  def one_of_type?(type) do
    get_string_name(type) == "OneOfType"
  end

  @spec union_type?(struct) :: boolean
  def union_type?(type) do
    get_string_name(type) == "UnionType"
  end

  # Predicate functions - end

end
