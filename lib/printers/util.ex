defmodule JS2E.Printers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema printers.
  """

  @indent_size 4

  @spec indent(pos_integer) :: String.t
  def indent(tabs \\ 1) do
    String.pad_leading("", tabs * @indent_size)
  end

  @spec upcase_first(String.t) :: String.t
  def upcase_first(str) do
    String.upcase(String.at str, 0) <> String.slice(str, 1..-1)
  end

  @spec downcase_first(String.t) :: String.t
  def downcase_first(str) do
    String.downcase(String.at str, 0) <> String.slice(str, 1..-1)
  end

  @spec get_string_name(map) :: String.t
  def get_string_name(instance) do
    instance.__struct__
    |> to_string
    |> String.split(".")
    |> List.last
  end

end
