# JSON schema to Elm

Generates Elm types, JSON decoders, JSON encoders, and Fuzz tests from JSON
schema specifications.

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

A proper description of which properties are mandatory and how the generator
works is still in progress, but feel free to take a look at the `examples`
folder which contains an example of a pair of JSON schemas and their
corresponding Elm output. Likewise, representations of each of the different
JSON schema types are described in the `lib/types` folder.

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
    Decode.string
        |> andThen
            (\color ->
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
            )


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
import Data.Definitions as Definitions


type alias Circle =
    { center : Definitions.Point
    , color : Maybe Definitions.Color
    , radius : Float
    }


circleDecoder : Decoder Circle
circleDecoder =
    decode Circle
        |> required "center" Definitions.pointDecoder
        |> optional "color" (nullable Definitions.colorDecoder) Nothing
        |> required "radius" Decode.float


encodeCircle : Circle -> Value
encodeCircle circle =
    let
        center =
            [ ( "center", Definitions.encodePoint circle.center ) ]

        color =
            case circle.color of
                Just color ->
                    [ ( "color", Definitions.encodeColor color ) ]

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

Furthermore, `js2e` also generates test files for the generated decoders and
encoders, which fuzzes instances of a given Elm type and tests that encoding it
as JSON and decoding it back into Elm returns the original instance of that
generated Elm type. In the above case, the following test files,
`tests/Data/CircleTests.elm` and `tests/Data/DefinitionsTests.elm`, are
generated:

``` elm
module Data.CircleTests exposing (..)

-- Tests: Schema for a circle shape

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Json.Decode as Decode
import Data.Circle exposing (..)
import Data.DefinitionsTests as Definitions


circleFuzzer : Fuzzer Circle
circleFuzzer =
    Fuzz.map3
        Circle
        Definitions.pointFuzzer
        (Fuzz.maybe Definitions.colorFuzzer)
        Fuzz.float


encodeDecodeCircleTest : Test
encodeDecodeCircleTest =
    fuzz circleFuzzer "can encode and decode Circle object" <|
        \circle ->
            circle
                |> encodeCircle
                |> Decode.decodeValue circleDecoder
                |> Expect.equal (Ok circle)
```
and

``` elm
module Data.DefinitionsTests exposing (..)

-- Tests: Schema for common types

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Json.Decode as Decode
import Data.Definitions exposing (..)


colorFuzzer : Fuzzer Color
colorFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Red
        , Fuzz.constant Yellow
        , Fuzz.constant Green
        , Fuzz.constant Blue
        ]


encodeDecodeColorTest : Test
encodeDecodeColorTest =
    fuzz colorFuzzer "can encode and decode Color object" <|
        \color ->
            color
                |> encodeColor
                |> Decode.decodeValue colorDecoder
                |> Expect.equal (Ok color)


pointFuzzer : Fuzzer Point
pointFuzzer =
    Fuzz.map2
        Point
        Fuzz.float
        Fuzz.float


encodeDecodePointTest : Test
encodeDecodePointTest =
    fuzz pointFuzzer "can encode and decode Point object" <|
        \point ->
            point
                |> encodePoint
                |> Decode.decodeValue pointDecoder
                |> Expect.equal (Ok point)

```

Finally, `js2e` also generates package config files, `package.json` and
`elm-package.json` making it easy to test that the generated Elm code is
behaving as expected. Thus, if we supply the following directory structure to
`js2e` in the above case:

```
.
└── js2e_input/
    ├── definitions.json
    └── circle.json
```

the following new directory structure is generated:

```
.
└── js2e_output/
    ├── package.json
    ├── elm-package.json
    ├── Data/
    │   ├── Circle.elm
    │   └── Definitions.elm
    └── tests/
        ├── elm-package.json
        └── Data/
            ├── CircleTests.elm
            └── DefinitionsTests.elm
```

containing the files described above along with the needed package config files
to compile and run the tests.

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
