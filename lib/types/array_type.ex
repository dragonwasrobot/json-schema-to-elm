defmodule JS2E.Types.ArrayType do
  @moduledoc ~S"""
  Represents a custom 'array' type definition in a JSON schema.

  JSON Schema:

      "rectangles": {
        "type": "array",
        "items": {
          "$ref": "#/rectangle"
        }
      }

  Elixir intermediate representation:

      %ArrayType{name: "rectangles",
                 path: ["#", "rectangles"],
                 items: ["#", "rectangles", "items"]}

  Elm code generated:

  - Decoder definition

      rectanglesDecoder : Decoder (List Rectangle)
      rectanglesDecoder =
          Decode.list rectangleDecoder

  - Decoder usage

      |> required "rectangles" rectanglesDecoder

  - Encoder definition

      encodeRectangles : List Rectangle -> Value
      encodeRectangles rectangles =
          Encode.list <| List.map encodeRectangle <| rectangles

  - Encoder usage

      encodeRectangles rectangles

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{
          name: String.t(),
          path: TypePath.t(),
          items: TypePath.t()
        }

  defstruct [:name, :path, :items]

  @spec new(String.t(), TypePath.t(), TypePath.t()) :: t
  def new(name, path, items) do
    %__MODULE__{name: name, path: path, items: items}
  end
end
