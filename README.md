# JSON schema to Elm

Generates Elm types, JSON decoders and JSON encoders from JSON schema
specifications.

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Download latest release at:
  https://github.com/dragonwasrobot/json-schema-to-elm/releases, or
- clone this repository:
  `git clone git@github.com:dragonwasrobot/json-schema-to-elm.git`, then
- build an executable: `MIX_ENV=prod mix build`, and
- rune the executable, `js2e`, that has now been created in your current working
  directory.

## Usage

Run `./js2e` for usage instructions.

> Note: The `js2e` tool only tries to resolve references for the file(s) you
> pass it. So if you need to generate Elm code from more than one file you
> have to pass it the enclosing directory of the relevant JSON schema files,
> in order for it to be able to resolve the references correctly.

A proper description of which properties are mandatory are how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.

The tool aims to produce `elm-make`-like errors if something is missing,
mispelled or cannot be resolved in the supplied JSON schema file(s). If you
experience errors that look more like stack traces, feel free to open an issue
so it can be fixed.

## Example

If we supply `js2e` with the following JSON schema file, `definitions.json`:
``` json
{
    "$schema": "http://json-schema.org/draft-04/schema#",
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

it produces the following Elm file, `Data/Definitions.elm`:

``` elm
module Data.Definitions exposing (..)

-- Schema for common types

import Json.Decode as Decode
    exposing
        ( succeed
        , fail
        , map
        , maybe
        , field
        , index
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
        , object
        , list
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
        object <| x ++ y
```

which contains an Elm type for the `color` and `point` definitions along with
their corresponding JSON decoders and encoders.

Furthermore, if we instead supply `js2e` with a directory of JSON schema files
that have references across files, e.g.

``` json
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "Circle",
    "id": "http://example.com/circle.json",
    "description": "Schema for a circle shape",
    "type": "object",
    "properties": {
        "center": {
            "$ref": "http://example.com/definitions.json#point"
        },
        "radius": {
            "type": "number"
        },
        "color": {
            "$ref": "http://example.com/definitions.json#color"
        }
    },
    "required": ["center", "radius"]
}
```

then the corresponding Elm file, `Data/Circle.elm`, will import the
definitions (types, encoders and decoders) from the other Elm module,
`Data/Definitions.elm`.

``` elm
module Data.Circle exposing (..)

-- Schema for a circle shape

import Json.Decode as Decode
    exposing
        ( succeed
        , fail
        , map
        , maybe
        , field
        , index
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
        , object
        , list
        )
import Data.Definitions


type alias Circle =
    { center : Data.Definitions.Point
    , color : Maybe Data.Definitions.Color
    , radius : Float
    }


circleDecoder : Decoder Circle
circleDecoder =
    decode Circle
        |> required "center" Data.Definitions.pointDecoder
        |> optional "color" (Decode.string |> andThen Data.Definitions.colorDecoder |> maybe) Nothing
        |> required "radius" Decode.float


encodeCircle : Circle -> Value
encodeCircle circle =
    let
        center =
            [ ( "center", Data.Definitions.encodePoint circle.center ) ]

        color =
            case circle.color of
                Just color ->
                    [ ( "color", Data.Definitions.encodeColor color ) ]

                Nothing ->
                    []

        radius =
            [ ( "radius", Encode.float circle.radius ) ]
    in
        object <|
            center
                ++ color
                ++ radius
```

## Contributing

If you feel like something is missing/wrong or if I've misinterpreted the JSON
schema spec, feel free to open an issue so we can discuss a solution.

### Development

As noted in the installation section, the project is written
in [Elixir](http://elixir-lang.org/) - as I found it to be a more suitable tool
for the job than Elm, and uses the `mix` tool for building.

#### Compiling

Install dependencies

    mix deps.get

Compile project

    mix compile

and you are good to go.

#### Tests

Run the standard mix task

    mix test

for test coverage run

    mix coveralls.html
