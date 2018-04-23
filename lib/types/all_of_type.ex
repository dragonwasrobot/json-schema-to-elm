defmodule JS2E.Types.AllOfType do
  @moduledoc ~S"""
  Represents a custom 'all_of' type definition in a JSON schema.

  JSON Schema:

  The following example schema has the path "#/definitions/fancyCircle"

      {
        "allOf": [
          {
            "type": "object",
            "properties": {
              "color": {
                "$ref": "#/definitions/color"
              },
              "description": {
                "type": "string"
              }
            },
            "required": [ "color" ]
          },
          {
            "$ref": "#/definitions/circle"
          }
        ]
      }

  Where "#/definitions/color" resolves to:

      {
        "type": "string",
        "enum": ["red", "yellow", "green"]
      }

  Where "#/definitions/circle" resolves to:

      {
         "type": "object",
         "properties": {
           "radius": {
             "type": "number"
           }
         },
         "required": [ "radius" ]
      }

  Elixir intermediate representation:

      %AllOfType{name: "fancyCircle",
                 path: ["#", "definitions", "fancyCircle"],
                 types: [["#", "definitions", "fancyCircle", "allOf", "0"],
                         ["#", "definitions", "fancyCircle", "allOf", "1"]]}

  Elm code generated:

  - Type definition

      type alias FancyCircle =
          { color : Color
          , description : Maybe String
          , radius : Float
          }

  - Decoder definition

      fancyCircleDecoder : Decoder FancyCircle
      fancyCircleDecoder =
          decode FancyCircle
              |> required "color" (Decode.string |> andThen colorDecoder)
              |> optional "description" (nullable Decode.string) Nothing
              |> required "radius" Decode.float

  - Decoder usage

      |> required "fancyCircle" fancyCircleDecoder

  - Encoder definition

      encodeFancyCircle : FancyCircle -> Value
      encodeFancyCircle fancyCircle =
          let
              color =
                  encodeColor fancyCircle.color

              description =
                  case fancyCircle.description of
                      Just description ->
                          [ ( "description", Encode.string description ) ]

                      Nothing ->
                          []

              radius =
                  [ ( "radius", Encode.float circle.radius ) ]
          in
              object <| color ++ description ++ radius

  - Encoder usage

      encodeFancyCircle fancyCircle

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{
          name: String.t(),
          path: TypePath.t(),
          types: [TypePath.t()]
        }

  defstruct [:name, :path, :types]

  @spec new(String.t(), TypePath.t(), [TypePath.t()]) :: t
  def new(name, path, types) do
    %__MODULE__{name: name, path: path, types: types}
  end
end
