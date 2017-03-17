defmodule JS2E.Types.SchemaDefinition do
  @moduledoc ~S"""
  An intermediate representation of the root of a JSON schema document.
  """

  @type t :: %__MODULE__{id: String.t,
                         title: String.t,
                         description: String.t,
                         types: Types.typeDictionary}

  defstruct [:id, :title, :description, :types]
end
