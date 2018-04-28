defmodule JS2E.Printer.Utils.Indentation do
  @moduledoc ~S"""
  Module containing various utility functions for normalizing names of
  identifiers in the Elm output.
  """

  @indent_size 4

  @doc ~S"""
  Returns a chunk of indentation.

  ## Examples

  iex> indent(2)
  "        "

  """
  @spec indent(pos_integer) :: String.t()
  def indent(tabs \\ 1) when is_integer(tabs) do
    String.pad_leading("", tabs * @indent_size)
  end

  @doc ~S"""
  Remove excessive newlines of a string.
  """
  @spec trim_newlines(String.t()) :: String.t()
  def trim_newlines(str) do
    String.trim(str) <> "\n"
  end
end
