defmodule JS2E.Types.EnumType do
  @moduledoc ~S"""
  Represents a custom 'enum' type definition in a JSON schema.

  Limitations:

  While the standard states

      Elements in the array MAY be of any type, including null.

  We limit the valid types of the elements such that it MUST either be an array
  of strings or it MUST be an array of numbers/integers, and nothing else.

  Furthermore, the "type" keyword MUST be present and the values of the "enum"
  keyword array MUST be of the same type as specified by the "type" keyword.

  JSON Schema:

      "color": {
        "type": "string",
        "enum": ["none", "green", "orange", "blue", "yellow", "red"]
      }

  Elixir intermediate representation:

      %EnumType{name: "color",
                path: ["#", "color"],
                type: "string",
                enum: ["none", "green", "orange",
                       "blue", "yellow", "red"]}

  Elm code generated:

  - Type definition

      type Color
          = None
          | Green
          | Orange
          | Blue
          | Yellow
          | Red

  - Decoder definition

      colorDecoder : String -> Decode Color
      colorDecoder color =
          case color of
              "none" ->
                  succeed None

              "green" ->
                  succeed Green

              ...

              _ ->
                  fail <| "Unknown color type: " ++ color

  - Usage

      |> required "color" (string |> andThen colorDecoder)

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t,
                         path: TypePath.t,
                         type: String.t,
                         values: [(String.t | number)]}

  defstruct [:name, :path, :type, :values]
end
