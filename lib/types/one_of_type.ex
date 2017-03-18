defmodule JS2E.Types.OneOfType do
  @moduledoc ~S"""
  Represents a custom 'one_of' type definition in a JSON schema.

  JSON Schema:

      "shape": {
        "oneOf": [
          {
            "$ref": "#/definitions/circle"
          },
          {
            "$ref": "#/definitions/rectangle"
          }
        ]
      }

  Elixir intermediate representation:

      %OneOfType{name: "shape",
                 path: ["#", "shape"],
                 types: ["#/shape/0",
                         "#/shape/1"]}

  Elm code generated:

  - Type definition

      type Shape
          = ShapeCircle Circle
          | ShapeRectangle Rectangle

  - Decoder definition

      shapeDecoder : Decoder Shape
      shapeDecoder =
          oneOf
              [ circleDecoder
                |> andThen (succeed << ShapeCircle)
              , rectangleDecoder
                |> andThen (succeed << ShapeRectangle)
              ]

  - Usage

  |> custom (field "shape" shapeDecoder)

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t,
                         types: [String.t]}

  defstruct [:name, :path, :types]
end
