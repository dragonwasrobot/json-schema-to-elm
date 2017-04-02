# JSON schema to Elm

Generates Elm types, JSON decoders and JSON encoders from JSON schema
specifications.

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Clone this repository: `git clone
  git@github.com:dragonwasrobot/json-schema-to-elm.git`
- Build an executable: `MIX_ENV=prod mix build`
- An executable, `js2e`, has now been created in your current working directory.

## Usage

Run `./js2e` for usage instructions.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.

## Example

If we supply `js2e` with the following JSON schema file, `definitions.json`:
``` json
{
    "$schema": "http://json-schema.org/draft-04/schema",
    "title": "Definitions",
    "id": "http://example.com/definitions.json",
    "description": "Schema for common types",
    "definitions": {
        "color": {
            "id": "#color",
            "type": "string",
            "enum": [ "red", "yellow", "green", "blue" ]
        },
        "point": {
            "id": "#point",
            "type": "object",
            "properties": {
                "x": {
                    "type": "number"
                },
                "y": {
                    "type": "number"
                }
            },
            "required": [ "x", "y" ]
        }
    }
}
```

it produces the following Elm file, `Domain/Definitions.elm`:

``` elm
module Domain.Definitions exposing (..)

-- Schema for common types

import Json.Decode as Decode
    exposing
        ( float
        , int
        , string
        , list
        , succeed
        , fail
        , map
        , maybe
        , field
        , at
        , andThen
        , oneOf
        , nullable
        , Decoder
        )
import Json.Decode.Pipeline
    exposing
        ( decode
        , required
        , optional
        , custom
        )
import Json.Encode as Encode
    exposing
        ( Value
        , float
        , int
        , string
        , list
        , object
        )


type Color
    = Red
    | Yellow
    | Green
    | Blue


type alias Point =
    { x : Float
    , y : Float
    }


colorDecoder : String -> Decoder Color
colorDecoder color =
    case color of
        "red" ->
            succeed Red

        "yellow" ->
            succeed Yellow

        "green" ->
            succeed Green

        "blue" ->
            succeed Blue

        _ ->
            fail <| "Unknown color type: " ++ color


pointDecoder : Decoder Point
pointDecoder =
    decode Point
        |> required "x" Decode.float
        |> required "y" Decode.float


encodeColor : Color -> Value
encodeColor color =
    case color of
        Red ->
            Encode.string "red"

        Yellow ->
            Encode.string "yellow"

        Green ->
            Encode.string "green"

        Blue ->
            Encode.string "blue"


encodePoint : Point -> Value
encodePoint point =
    let
        x =
            [ ( "x", Encode.float point.x ) ]

        y =
            [ ( "y", Encode.float point.y ) ]
    in
        object <|
            x
                ++ y
```

which contains an Elm type for the `color` and `point` definitions along with
their corresponding JSON decoders and encoders.

Furthermore, if we supply `js2e` with another JSON schema file that references
any of the definitions in `definitions.json`, e.g.

``` json
{ "$ref" : "http://example.com/definitions.json#point" }
```

then the corresponding Elm file output will import the definitions `Point`,
`pointDecoder` and `encodePoint` from `Domain.Definitions`.
