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

  @type t :: %__MODULE__{name: String.t,
                         path: Types.typeIdentifier}

  defstruct [:name, :path]
end
