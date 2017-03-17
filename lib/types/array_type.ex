defmodule JS2E.Types.ArrayType do
  @moduledoc ~S"""
  Represents a custom 'array' type definition in a JSON schema.

  Limitations:

  While the standard states

      The value of "items" MUST be either a schema or array of schemas.

  We limit the value of "items" such that it MUST be a schema and nothing else.

  Furthermore, the "type" keyword MUST be present and have the value "array".

  JSON Schema:

      "rectangles": {
        "type": "array",
        "items": {
          "$ref": "#/rectangle"
        }
      }

  Elixir intermediate representation:

      %ArrayType{name: "rectangles",
                 path: "#/rectangles",
                 items: "#/rectangles/items"}

  Elm code generated:

  - Decoder definition

      rectanglesDecoder : Decoder (List Rectangle)
      rectanglesDecoder =
          list rectangleDecoder

  - Usage

      |> required "rectangles" rectanglesDecoder

  """

  @type t :: %__MODULE__{name: String.t,
                         path: String.t,
                         items: String.t}

  defstruct [:name, :path, :items]
end
