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
