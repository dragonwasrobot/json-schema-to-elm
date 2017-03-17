defmodule DecoderGenerator.Types.ArrayType do
  @moduledoc ~S"""
  Represents a custom 'array' type definition in a JSON schema.

  Limitations:

  While the standard states

      The value of "items" MUST be either a schema or array of schemas.

  We limit the value of "items" such that it MUST be a schema and nothing else.

  Furthermore, the "type" keyword MUST be present and have the value "array".

  JSON Schema:

      {
        "type": "array",
        "items": {
          "$ref": "#/rectangle"
        }
      }

  Elixir intermediate representation:

      "#" => %ArrayType{name: "root",
                        path: "#",
                        items: "#/items"}

      "#/items" => %TypeReference{name: "items",
                                  path: "#/rectangle"}

  Elm:

      rootDecoder : Decoder (list Rectangle)
      rootDecoder =
          list rectangleDecoder

  We resolve "#/rectangle" to the Rectangle type and use it
  directly in the decoder.
  """

  @type t :: %DecoderGenerator.Types.ArrayType{
    name: String.t,
    path: String.t,
    items: String.t}

  defstruct [:name, :path, :items]
end
