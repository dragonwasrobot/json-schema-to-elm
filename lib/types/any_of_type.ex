defmodule JS2E.Types.AnyOfType do
  @moduledoc ~S"""
  Represents a custom 'any_of' type definition in a JSON schema.

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

      %AnyOfType{name: "fancyCircle",
                 path: ["#", "definitions", "fancyCircle"],
                 types: [["#", "definitions", "fancyCircle", "allOf", "0"],
                         ["#", "definitions", "fancyCircle", "allOf", "1"]]}

  Elm code generated:

  - Type definition

      type alias FancyCircle =
          { zero : Maybe Zero
          , circle : Maybe Circle
          }

  - Decoder definition

      fancyCircleDecoder : Decoder FancyCircle
      fancyCircleDecoder =
          decode FancyCircle
              |> custom (nullable zeroDecoder)
              |> custom (nullable circleDecoder)

  - Decoder usage

      |> required "shape" shapeDecoder

  - Encoder definition

      encodeFancyCircle : FancyCircle -> Value
      encodeFancyCircle fancyCircle =
          let
              color =
                  fancyCircle.zero
                      |> Maybe.map
                          (\zero ->
                              [ ( "color", encodeColor zero.color ) ]
                          )
                      |> Maybe.withDefault []

              description =
                  fancyCircle.zero
                      |> Maybe.map
                          (\zero ->
                              zero.description
                                  |> Maybe.map
                                      (\description ->
                                          [ ( "description", Encode.string description ) ]
                                      )
                                  |> Maybe.withDefault []
                          )
                      |> Maybe.withDefault []

              radius =
                  fancyCircle.circle
                      |> Maybe.map
                          (\circle ->
                              [ ( "radius", Encode.float circle.radius ) ]
                          )
                      |> Maybe.withDefault []
          in
              object <|
                  color ++ description ++ radius

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
