defmodule DecoderGenerator.Types.ObjectType do
  @moduledoc ~S"""
  Represents a custom 'object' type definition in a JSON schema.

  JSON Schema:

      "circle": {
        "type": "object",
        "properties": {
          "color": {
            "$ref": "#/color"
          },
          "title": {
            "type": "string"
          },
          "radius": {
            "type": "number"
          }
        },
        "required": [ "color", "radius" ]
      }

  Elixir intermediate representation:

      %ObjectType{name: "circle",
                  path: "#/circle",
                  required: ["color", "radius"],
                  properties: %{"color" => "#/circle/properties/color",
                                "title" => "#/circle/properties/title",
                                "radius" => "#/circle/properties/radius"}}

  Elm code generated:

  - Type definitions

      type alias Circle =
          { color : Color
          , title : Maybe String
          , radius : Float
          }

  - Decoder definition

      circleDecoder : Decoder Circle
      circleDecoder =
          decode Circle
              |> required "color" colorDecoder
              |> optional "title" (nullable string) Nothing
              |> required "radius" float

  - Usage

      |> required "circle" circleDecoder

  """

  @type t :: %__MODULE__{name: String.t,
                         path: String.t,
                         properties: %{required(String.t) => String.t},
                         required: [String.t]}

  defstruct [:name, :path, :properties, :required]
end
