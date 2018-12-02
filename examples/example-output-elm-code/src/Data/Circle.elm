module Data.Circle exposing
    ( Circle
    , circleDecoder
    , encodeCircle
    )

-- Schema for a circle shape

import Data.Definitions as Definitions
import Data.Utils
    exposing
        ( encodeNestedOptional
        , encodeNestedRequired
        , encodeOptional
        , encodeRequired
        )
import Json.Decode as Decode
    exposing
        ( Decoder
        , andThen
        , at
        , fail
        , field
        , index
        , map
        , maybe
        , nullable
        , oneOf
        , succeed
        )
import Json.Decode.Pipeline
    exposing
        ( custom
        , optional
        , required
        )
import Json.Encode as Encode
    exposing
        ( Value
        , list
        , object
        )


type alias Circle =
    { center : Definitions.Point
    , color : Maybe Definitions.Color
    , radius : Float
    }


circleDecoder : Decoder Circle
circleDecoder =
    succeed Circle
        |> required "center" Definitions.pointDecoder
        |> optional "color" (nullable Definitions.colorDecoder) Nothing
        |> required "radius" Decode.float


encodeCircle : Circle -> Value
encodeCircle circle =
    []
        |> encodeRequired "center" circle.center Definitions.encodePoint
        |> encodeOptional "color" circle.color Definitions.encodeColor
        |> encodeRequired "radius" circle.radius Encode.float
        |> Encode.object
