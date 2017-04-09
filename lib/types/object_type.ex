defmodule JS2E.Types.ObjectType do
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
                  path: ["#", "circle"],
                  required: ["color", "radius"],
                  properties: %{
                      "color" => ["#", "circle", "properties", "color"],
                      "title" => ["#", "circle", "properties", "title"],
                      "radius" => ["#", "circle", "properties", "radius"]}}

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
              |> optional "title" (nullable Decode.string) Nothing
              |> required "radius" Decode.float

  - Decoder usage

      |> required "circle" circleDecoder

  - Encoder definition

      encodeCircle : Circle -> Value
      encodeCircle circle =
          let
              color =
                  [ ("color", encodeColor circle.color ) ]

              title =
                  case circle.title of
                      Just title ->
                         [ ( "title", Encode.string title ) ]

                      Nothing ->
                         []

              radius =
                  [ ( "radius", Encode.float circle.radius ) ]
          in
              object <| color ++ title ++ radius

  - Encoder usage

      encodeCircle circle

  """

  alias JS2E.{TypePath, Types}

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t,
                         properties: Types.propertyDictionary,
                         required: [String.t]}

  defstruct [:name, :path, :properties, :required]

  @spec new(String.t, TypePath.t, Types.propertyDictionary, [String.t]) :: t
  def new(name, path, properties, required) do
    %__MODULE__{name: name,
                path: path,
                properties: properties,
                required: required}
  end

end
