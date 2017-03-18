defmodule JS2E.Parsers.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema parsers.
  """

  alias JS2E.Types
  alias JS2E.TypePath

  @doc ~S"""
  Creates a new type dictionary based on the given type definition
  and an optional ID.
  """
  @spec create_type_dict(Types.typeDefinition, TypePath.t, URI.t | nil)
  :: Types.typeDictionary
  def create_type_dict(type_def, path, id) do

    string_path = path |> TypePath.to_string

    if id != nil do
      string_id = id |> to_string

      %{string_path => type_def,
        string_id => type_def}
    else
      %{string_path => type_def}
    end
  end

end
