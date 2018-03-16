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
            center ++ color ++ radius
