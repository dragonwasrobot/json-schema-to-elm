defmodule JS2E.Printers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema printers.
  """

  alias JS2E.Types
  alias JS2E.Types.PrimitiveType

  @indent_size 4

  @doc ~S"""
  Returns a chunk of indentation.

  ## Examples

      iex> JS2E.Printers.Util.indent(2)
      "        "

  """
  @spec indent(pos_integer) :: String.t
  def indent(tabs \\ 1) when is_integer(tabs) do
    String.pad_leading("", tabs * @indent_size)
  end

  @doc ~S"""
  Upcases the first letter of a string.

  ## Examples

      iex> JS2E.Printers.Util.upcase_first("foobar")
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

      iex> JS2E.Printers.Util.downcase_first("Foobar")
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

  @doc ~S"""
  Remove excessive newlines of a string.
  """
  @spec trim_newlines(String.t) :: String.t
  def trim_newlines(str) do
    String.trim(str) <> "\n"
  end

  @doc ~S"""
  Returns the encoder name given a JSON schema type definition.
  """
  @spec create_encoder_name(Types.typeDefinition) :: String.t
  def create_encoder_name(type) do

    if primitive_type?(type) do
      determine_primitive_type_encoder(type)
    else

      type_name = type.name
      if type_name == "#" do
        "encodeRoot"
      else
        "encode#{upcase_first type_name}"
      end

    end
  end

  @spec determine_primitive_type_encoder(PrimitiveType.t) :: String.t
  defp determine_primitive_type_encoder(primitive_type) do
    type_value = primitive_type.type

    case type_value do
      "integer" ->
        "Encode.int"

      "number" ->
        "Encode.float"

      _ ->
        "Encode.#{type_value}"
    end
  end

  @doc ~S"""
  Get the string shortname of the given struct.

  ## Examples

      iex> JS2E.Printers.Util.get_string_name(%JS2E.Types.PrimitiveType{})
      "PrimitiveType"

  """
  @spec get_string_name(struct) :: String.t
  def get_string_name(instance) when is_map(instance) do
    instance.__struct__
    |> to_string
    |> String.split(".")
    |> List.last
  end

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

end
