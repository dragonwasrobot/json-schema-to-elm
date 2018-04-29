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

## Error reporting

Any errors encountered by the `js2e` tool while parsing the JSON schema files or
printing the Elm code output, is reported in an Elm-like style, e.g.

```
--- UNKNOWN NODE TYPE -------------------------------------- all_of_example.json

The value of "type" at '#/allOf/0/properties/description' did not match a known node type

    "type": "strink"
            ^^^^^^^^

Was expecting one of the following types

    ["null", "boolean", "object", "array", "number", "integer", "string"]

Hint: See the specification section 6.25. "Validation keywords - type"
<http://json-schema.org/latest/json-schema-validation.html#rfc.section.6.25>
```

or

```
--- UNRESOLVED REFERENCE ----------------------------------- all_of_example.json


The following reference at `#/allOf/0/color` could not be resolved

    "$ref": #/definitions/kolor
            ^^^^^^^^^^^^^^^^^^^


Hint: See the specification section 9. "Base URI and dereferencing"
<http://json-schema.org/latest/json-schema-core.html#rfc.section.9>
```

If you encounter an error while using `js2e` that does not mimic the above
Elm-like style, but instead looks like an Elixir stacktrace, please report this
as a bug by opening an issue and includin a JSON schema example that recreates
the error.

## Contributing

If you feel like something is missing/wrong or if I've misinterpreted the JSON
schema spec, feel free to open an issue so we can discuss a solution.

Please consult `CONTRIBUTING.md` first before opening an issue.
