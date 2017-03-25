module Domain.Decoders.Circle exposing (..)

-- Schema for a circle shape

import Json.Decode as Decode
    exposing
        ( int
        , string
        , succeed
        , fail
        , list
        , map
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
import Domain.Decoders.Definitions
    exposing
        ( Color
        , colorDecoder
        , Point
        , pointDecoder
        )


type alias Root =
    { center : Maybe Point
    , color : Maybe Color
    , radius : Maybe Float
    }


rootDecoder : Decoder Root
rootDecoder =
    decode Root
        |> optional "center" (nullable pointDecoder) Nothing
        |> optional "color" (nullable colorDecoder) Nothing
        |> optional "radius" (nullable float) Nothing
