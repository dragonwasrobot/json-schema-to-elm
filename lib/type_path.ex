defmodule JS2E.TypePath do
  @moduledoc ~S"""
  Module for creating, manipulating, and printing type paths.
  """

  @type t :: [String.t()]

  @doc ~S"""
  Converts a json schema path like "#/definitions/foo" into its corresponding
  `JS2E.TypePath`.

  ## Examples

      iex> JS2E.TypePath.from_string("")
      []

      iex> JS2E.TypePath.from_string("#")
      ["#"]

      iex> JS2E.TypePath.from_string("#/definitions/foo")
      ["#", "definitions", "foo"]

  """
  @spec from_string(String.t()) :: t
  def from_string(string) do
    string
    |> String.split("/")
    |> Enum.filter(fn segment -> segment != "" end)
  end

  @doc ~S"""
  Converts a `JS2E.TypePath` back to its string representation.

  ## Examples

      iex> JS2E.TypePath.to_string([])
      ""

      iex> JS2E.TypePath.to_string(["#"])
      "#"

      iex> JS2E.TypePath.to_string(["#", "definitions", "foo"])
      "#/definitions/foo"

  """
  @spec to_string(t) :: String.t()
  def to_string(segments) do
    segments |> Enum.join("/")
  end

  @doc ~S"""
  Adds a child to an existing `JS2E.TypePath`.

  ## Examples

      iex> JS2E.TypePath.add_child(["#", "definitions", "foo"], "")
      ["#", "definitions", "foo"]

      iex> JS2E.TypePath.add_child(["#", "definitions"], "bar")
      ["#", "definitions", "bar"]

  """
  @spec add_child(t, String.t()) :: t
  def add_child(segments, segment) do
    if segment != "" do
      segments ++ [segment]
    else
      segments
    end
  end

  @doc ~S"""
  Returns true if the specified type can be treated as a `JS2E.TypePath`. Note
  that it also returns false if the specified type is a string representation of
  a `JS2E.TypePath`.

  ## Examples

      iex> JS2E.TypePath.type_path?("")
      false

      iex> JS2E.TypePath.type_path?("#/definitions/foo")
      false

      iex> JS2E.TypePath.type_path?([])
      false

      iex> JS2E.TypePath.type_path?(["bar"])
      false

      iex> JS2E.TypePath.type_path?(["#"])
      true

      iex> JS2E.TypePath.type_path?(["#", "foo"])
      true

  """
  @spec type_path?(any) :: boolean
  def type_path?(path) do
    is_list(path) && length(path) > 0 && Enum.fetch!(path, 0) == "#"
  end
end
