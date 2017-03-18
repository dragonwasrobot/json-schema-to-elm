defmodule JS2E.Types.TypeReference do
  @moduledoc ~S"""
  Represents a reference to a custom type definition in a JSON schema.

  JSON Schema:

      "self": {
          "$ref": "#/definitions/link"
      }

  Where "#/definitions/link" resolves to

      "definitions": {
          "link": {
              "type": "string"
          }
      }

  Elixir intermediate representation:

      %TypeReference{name: "self",
                     path: ["#", "definitions", "link"]}

  Elm code generated:

  - Usage

      |> required "self" string

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t}

  defstruct [:name, :path]
end
