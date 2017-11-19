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
                 types: [["#", "shape", "oneOf", "0"],
                         ["#", "shape", "oneOf", "1"]]}

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

  - Decoder usage

      |> required "shape" shapeDecoder

  - Encoder definition

      encodeShape : Shape -> Value
      encodeShape shape =
          case shape of
              ShapeCircle circle ->
                  encodeCircle circle

              ShapeRectangle rectangle ->
                  encodeRectangle rectangle

  - Encoder usage

      encodeShape shape

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t,
                         types: [TypePath.t]}

  defstruct [:name, :path, :types]

  @spec new(String.t, TypePath.t, [TypePath.t]) :: t
  def new(name, path, types) do
    %__MODULE__{name: name,
                path: path,
                types: types}
  end

end
