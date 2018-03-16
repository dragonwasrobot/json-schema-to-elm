defmodule JS2E.Types.UnionType do
  @moduledoc ~S"""
  Represents a custom 'union' type definition in a JSON schema.

  JSON Schema:

      "favoriteNumber": {
        "type": ["number", "integer", "null"]
      }

  Elixir intermediate representation:

      %UnionType{name: "favoriteNumber",
                 path: ["#", "favoriteNumber"],
                 types: ["number", "integer", "null"]}

  Elm code generated:

  - Type definition

      type FavoriteNumber
          = FavoriteNumber_F Float
          | FavoriteNumber_I Int

  - Decoder definition

      favoriteNumberDecoder : Decoder (Maybe FavoriteNumber)
      favoriteNumberDecoder =
          oneOf
              [ null Nothing
              , Decode.float |> andThen (succeed << FavoriteNumber_F)
              , Decode.int |> andThen (succeed << FavoriteNumber_I)
              ]

  - Decoder usage

    |> required "favoriteNumber" favoriteNumberDecoder

  - Encoder definition

      encodeFavoriteNumber : FavoriteNumber -> Value
      encodeFavoriteNumber favoriteNumber =
          case favoriteNumber of
              FavoriteNumber_F floatValue ->
                  Encode.float floatValue

              FavoriteNumber_I intValue ->
                  Encode.int intValue

  - Encoder usage

      encodeFavoriteNumber favoriteNumber

  """

  alias JS2E.TypePath

  @type t :: %__MODULE__{name: String.t(), path: TypePath.t(), types: [String.t()]}

  defstruct [:name, :path, :types]

  @spec new(String.t(), TypePath.t(), [String.t()]) :: t
  def new(name, path, types) do
    %__MODULE__{name: name, path: path, types: types}
  end
end
