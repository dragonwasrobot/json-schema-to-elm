defmodule JS2E.Types.TupleType do
  @moduledoc ~S"""
  Represents a custom 'tuple' type definition in a JSON schema.

  JSON Schema:

      "shapePair": {
        "type": "array",
        "items": [
          { "$ref": "#/rectangle" },
          { "$ref": "#/circle" }
        ]
      }

  Elixir intermediate representation:

      %TupleType{name: "shapePair",
                 path: ["#", "rectangles"],
                 items: [["#", "shapePair", "items", "0"],
                         ["#", "shapePair", "items", "1"]}

  Elm code generated:

  - Type definitions

      type alias ShapePair =
          ( Rectangle
          , Circle
          )

  - Decoder definition

      shapePairDecoder : Decoder ShapePair
      shapePairDecoder =
          map2 ShapePair
              (index 0 rectangleDecoder)
              (index 1 circleDecoder)

  - Decoder usage

      |> required "shapePair" shapePairDecoder

  - Encoder definition

      encodeShapePair : List ShapePair -> Value
      encodeShapePair (rectangle, circle) =
          Encode.list
              [ encodeRectangle rectangle
              , encodeCircle circle
              ]

  - Encoder usage

      encodeShapePair shapePair

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t,
                         items: TypePath.t}

  defstruct [:name, :path, :items]

  @spec new(String.t, TypePath.t, TypePath.t) :: t
  def new(name, path, items) do
    %__MODULE__{name: name,
                path: path,
                items: items}
  end

end
