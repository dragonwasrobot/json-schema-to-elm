# JSON Schema to Elm

### Status

[![Build Status](https://travis-ci.org/dragonwasrobot/json-schema-to-elm.svg?branch=master)](https://travis-ci.org/dragonwasrobot/json-schema-to-elm)

### Description

Generates Elm types, JSON decoders, JSON encoders, and Fuzz tests from JSON
schema specifications.

**Only supports - a subset of - JSON Schema draft v7.**

## Installation

This project requires that you already have [elixir](http://elixir-lang.org/)
and its build tool `mix` installed, this can be done with `brew install elixir`
or similar.

- Download latest release at:
  https://github.com/dragonwasrobot/json-schema-to-elm/releases, or
- clone this repository:
  `git clone git@github.com:dragonwasrobot/json-schema-to-elm.git`, then
- build an executable: `MIX_ENV=prod mix build` (Windows `cmd.exe`: `set "MIX_ENV=prod" && mix build`), and
- run the executable, `./js2e` (Windows: `escript .\js2e`), that has now been created in your current working
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
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Definitions",
    "$id": "http://example.com/definitions.json",
    "description": "Schema for common types",
    "definitions": {
        "color": {
            "$id": "#color",
            "type": "string",
            "enum": [ "red", "yellow", "green", "blue" ]
        },
        "point": {
            "$id": "#point",
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
module Data.Definitions exposing
    ( Color(..)
    , Point
    , colorDecoder
    , encodeColor
    , encodePoint
    , pointDecoder
    )

-- Schema for common types

import Data.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline
    exposing
        ( custom
        , optional
        , required
        )
import Json.Encode as Encode exposing (Value)


type Color
    = Red
    | Yellow
    | Green
    | Blue


type alias Point =
    { x : Float
    , y : Float
    }


colorDecoder : Decoder Color
colorDecoder =
    Decode.string |> Decode.andThen (parseColor >> Decode.fromResult)


parseColor : String -> Result String Color
parseColor color =
    case color of
        "red" ->
            Ok Red

        "yellow" ->
            Ok Yellow

        "green" ->
            Ok Green

        "blue" ->
            Ok Blue

        _ ->
            Err <| "Unknown color type: " ++ color


pointDecoder : Decoder Point
pointDecoder =
    Decode.succeed Point
        |> required "x" Decode.float
        |> required "y" Decode.float


encodeColor : Color -> Value
encodeColor color =
    color |> colorToString |> Encode.string


colorToString : Color -> String
colorToString color =
    case color of
        Red ->
            "red"

        Yellow ->
            "yellow"

        Green ->
            "green"

        Blue ->
            "blue"


encodePoint : Point -> Value
encodePoint point =
    []
        |> Encode.required "x" point.x Encode.float
        |> Encode.required "y" point.y Encode.float
        |> Encode.object
```

which contains an Elm type for the `color` and `point` definitions along with
their corresponding JSON decoders and encoders.

Furthermore, if we instead supply `js2e` with a directory of JSON schema files
that have references across files, e.g.

``` json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "http://example.com/circle.json",
    "title": "Circle",
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
module Data.Circle exposing
    ( Circle
    , circleDecoder
    , encodeCircle
    )

-- Schema for a circle shape

import Data.Definitions as Definitions
import Data.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline
    exposing
        ( custom
        , optional
        , required
        )
import Json.Encode as Encode exposing (Value)


type alias Circle =
    { center : Definitions.Point
    , color : Maybe Definitions.Color
    , radius : Float
    }


circleDecoder : Decoder Circle
circleDecoder =
    succeed Circle
        |> required "center" Definitions.pointDecoder
        |> optional "color" (Decode.nullable Definitions.colorDecoder) Nothing
        |> required "radius" Decode.float


encodeCircle : Circle -> Value
encodeCircle circle =
    []
        |> Encode.required "center" circle.center Definitions.encodePoint
        |> Encode.optional "color" circle.color Definitions.encodeColor
        |> Encode.required "radius" circle.radius Encode.float
        |> Encode.object
```

Furthermore, `js2e` also generates test files for the generated decoders and
encoders to make the generated code immediately testable. The generated test
files fuzzes instances of a given Elm type and tests that encoding it as JSON
and decoding it back into Elm returns the original instance of that generated
Elm type. In the above case, the following test files,
`tests/Data/CircleTests.elm` and `tests/Data/DefinitionsTests.elm`, are
generated:

``` elm
module Data.CircleTests exposing
    ( circleFuzzer
    , encodeDecodeCircleTest
    )


-- Tests: Schema for a circle shape

import Data.Circle exposing (..)
import Data.DefinitionsTests as Definitions
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Test exposing (..)


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
module Data.DefinitionsTests exposing
    ( colorFuzzer
    , encodeDecodeColorTest
    , encodeDecodePointTest
    , pointFuzzer
    )

-- Tests: Schema for common types

import Data.Definitions exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Json.Decode as Decode
import Test exposing (..)


colorFuzzer : Fuzzer Color
colorFuzzer =
    [ Red, Yellow, Green, Blue ]
        |> List.map Fuzz.constant
        |> Fuzz.oneOf


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
`elm.json`, and a `.tool-versions` file, making it easy to test that the
generated Elm code is behaving as expected. Note that the `.tool-versions` file
is not a file required by `elm` nor `elm-test` but instead a file used by the
`asdf` version manager, https://github.com/asdf-vm/asdf, to install and run the
correct compiler versions of `node` and `elm` specified in the `.tool-versions`
file for a given project.

Thus, if we supply the following directory structure to `js2e` in the above
case:

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
    ├── .tool-versions
    ├── package.json
    ├── elm.json
    ├── src/
    │   └── Data/
    │       ├── Encode.elm
    │       ├── Circle.elm
    │       └── Definitions.elm
    └── tests/
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
as a bug by opening an issue and including a JSON schema example that recreates
the error.

## Contributing

If you feel like something is missing/wrong or if I've misinterpreted the JSON
schema spec, feel free to open an issue so we can discuss a solution. Note that
the JSON schema parser has been moved to the new project,
https://github.com/dragonwasrobot/json_schema, so this repo only implements the
Elm code generators.

Please consult `CONTRIBUTING.md` first before opening an issue.
