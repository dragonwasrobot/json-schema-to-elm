defmodule JS2E.Types.SchemaDefinition do
  @moduledoc ~S"""
  An intermediate representation of the root of a JSON schema document.
  """

  alias JS2E.Types

  @type t :: %__MODULE__{id: URI.t,
                         title: String.t,
                         module: String.t,
                         description: String.t,
                         types: Types.typeDictionary}

  defstruct [:id, :title, :module, :description, :types]

  @spec new(URI.t, String.t, String.t, String.t, Types.typeDictionary) :: t
  def new(id, title, module, description, types) do
    %__MODULE__{id: id,
                title: title,
                module: module,
                description: description,
                types: types}
  end

end
