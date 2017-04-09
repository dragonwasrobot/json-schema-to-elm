defmodule JS2E.Parsers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema parsers.
  """

  alias JS2E.{Parser, TypePath, Types}

  @doc ~S"""
  Creates a new type dictionary based on the given type definition
  and an optional ID.
  """
  @spec create_type_dict(
    Types.typeDefinition,
    TypePath.t,
    URI.t | nil
  ) :: Types.typeDictionary
  def create_type_dict(type_def, path, id) do

    string_path = path |> TypePath.to_string

    if id != nil do
      string_id = if type_def.name == "#" do "#{id}#" else "#{id}" end

      %{string_path => type_def,
        string_id => type_def}
    else
      %{string_path => type_def}
    end
  end

  @doc ~S"""
  Creates a type dictionary based on a list of JSON schema objects.
  """
  @spec create_descendants_type_dict([map], URI.t, TypePath.t)
  :: Types.typeDictionary
  def create_descendants_type_dict(types, parent_id, path)
  when is_list(types) do
    types
    |> Enum.reduce({%{}, 0}, fn(child_node, {type_dict, idx}) ->

      child_name = to_string idx
      child_types = Parser.parse_type(child_node, parent_id, path, child_name)

      {Map.merge(type_dict, child_types), idx + 1}
    end)
    |> elem(0)
  end

  @doc ~S"""
  Returns a list of type paths based when given a type dictionary.
  """
  @spec create_types_list(Types.typeDictionary, TypePath.t) :: [TypePath.t]
  def create_types_list(type_dict, path) do
    type_dict
    |> Enum.reduce(%{}, fn({child_abs_path, child_type}, reference_dict) ->

      child_type_path = TypePath.add_child(path, child_type.name)

      if child_type_path == TypePath.from_string(child_abs_path) do
        Map.merge(reference_dict, %{child_type.name => child_type_path})
      else
        reference_dict
      end

    end)
    |> Map.values()
  end

end
