defmodule JS2E.Types.SchemaDefinition do
  @moduledoc ~S"""
  An intermediate representation of the root of a JSON schema document.
  """

  alias JS2E.Types

  @type t :: %__MODULE__{
          file_path: Path.t(),
          id: URI.t(),
          title: String.t(),
          description: String.t(),
          types: Types.typeDictionary()
        }

  defstruct [:file_path, :id, :title, :description, :types]

  @spec new(Path.t(), URI.t(), String.t(), String.t(), Types.typeDictionary()) ::
          t
  def new(file_path, id, title, description, types) do
    %__MODULE__{
      file_path: file_path,
      id: id,
      title: title,
      description: description,
      types: types
    }
  end
end
