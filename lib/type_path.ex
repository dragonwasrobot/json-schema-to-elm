defmodule JS2E.TypePath do
  @moduledoc ~S"""
  Module for creating, manipulating, and printing type paths.
  """

  @type t :: [String.t]

  @spec from_string(String.t) :: t
  def from_string(string) do
    string
    |> String.split("/")
    |> Enum.filter(fn segment -> segment != "" end)
  end

  @spec to_string(t) :: String.t
  def to_string(segments) do
    segments
    |> Enum.join("/")
  end

  @spec add_child(t, String.t) :: t
  def add_child(segments, segment) do
    if segment != "" do
      segments ++ [segment]
    else
      segments
    end
  end

  @spec type_path?(any) :: boolean
  def type_path?(path) do
    is_list(path) && Enum.fetch!(path, 0) == "#"
  end

end
