defmodule JS2E.Printers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema printers.
  """

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

end
