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
          { zero : Zero
          , circle : Circle
          }

  - Decoder definition

      fancyCircleDecoder : Decoder FancyCircle
      fancyCircleDecoder =
          decode FancyCircle
              |> custom zeroDecoder
              |> custom circleDecoder

  - Encoder definition

      encodeFancyCircle : FancyCircle -> Value
      encodeFancyCircle fancyCircle =
          let
              color =
                  [ ( "color", encodeColor fancyCircle.zero.color ) ]

              description =
                  fancyCircle.zero.description
                      |> Maybe.map
                          (\description ->
                              [ ( "description", Encode.string description ) ]
                          )
                      |> Maybe.withDefault []

              radius =
                  [ ( "radius", Encode.float fancyCircle.circle.radius ) ]
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
