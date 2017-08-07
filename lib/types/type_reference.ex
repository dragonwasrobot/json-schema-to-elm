defmodule JS2E.Types.TypeReference do
  @moduledoc ~S"""
  Represents a reference to a custom type definition in a JSON schema.

  JSON Schema:

      "self": {
        "$ref": "#/definitions/foo"
      }

      "other": {
        "$ref": "http://www.example.com/definitions.json#bar"
      }

  Where "#/definitions/foo" resolves to

      "definitions": {
        "foo": {
          "type": "string"
        }
      }

  and "http://www.example.com/definitions.json#bar" resolves to

      "definitions": {
        "bar": {
          "id": "#bar",
          "type": "number"
        }
      }

  Elixir intermediate representation:

      %TypeReference{name: "self",
                     path: ["#", "definitions", "link"]}

      %TypeReference{name: "other",
                     path: %URI{scheme: "http",
                                host: "www.example.com",
                                path: "/definitions.json",
                                fragment: "bar",
                                ...}}

  """

  alias JS2E.Types

  @type t :: %__MODULE__{name: String.t,
                         path: Types.typeIdentifier}

  defstruct [:name, :path]

  @spec new(String.t, Types.typeIdentifier) :: t
  def new(name, path) do
    %__MODULE__{name: name,
                path: path}
  end

end
