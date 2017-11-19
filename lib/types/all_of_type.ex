defmodule JS2E.Types.AllOfType do
  @moduledoc ~S"""
  Represents a custom 'all_of' type definition in a JSON schema.

  JSON Schema:

      "shape": {
        "allOf": [
          {
            "$ref": "#/definitions/circle"
          },
          {
            "$ref": "#/definitions/rectangle"
          }
        ]
      }

  Elixir intermediate representation:

      %AllOfType{name: "shape",
                 path: ["#", "shape"],
                 types: [["#", "shape", "allOf", "0"],
                         ["#", "shape", "allOf", "1"]]}

  Elm code generated:

  - Type definition

      type alias Shape =
          { circle : Circle
          , rectangle : Rectangle
          }

  - Decoder definition

      shapeDecoder : Decoder Shape
      shapeDecoder =
          decode Shape
              |> required "circle" circleDecoder
              |> required "rectangle" rectangleDecoder

  - Decoder usage

      |> required "shape" shapeDecoder

  - Encoder definition

      encodeShape : Shape -> Value
      encodeShape shape =
          let
              circle =
                  encodeCircle shape.circle

              rectangle =
                  encodeRectangle shape.rectangle
          in
              object <| circle ++ rectangle

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
