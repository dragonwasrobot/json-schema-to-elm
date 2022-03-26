module Data.Circle exposing (..)

-- Schema for a circle shape

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Decode.Pipeline
    exposing
        ( custom
        , optional
        , required
        )
import Json.Encode as Encode exposing (Value)
import Data.Encode as Encode
import Data.Definitions as Definitions


type alias Circle =
    { center : Definitions.Point
    , color : Maybe Definitions.Color
    , radius : Float
    }


circleDecoder : Decoder Circle
circleDecoder =
    Decode.succeed Circle
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
