module Domain.Circle exposing (..)

-- Schema for a circle shape

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
import Domain.Definitions
    exposing
        ( Color
        , colorDecoder
        , encodeColor
        , Point
        , pointDecoder
        , encodePoint
        )


type alias Root =
    { center : Point
    , color : Maybe Color
    , radius : Float
    }


rootDecoder : Decoder Root
rootDecoder =
    decode Root
        |> required "center" pointDecoder
        |> optional "color" (Decode.string |> andThen colorDecoder |> maybe) Nothing
        |> required "radius" Decode.float


encodeRoot : Root -> Value
encodeRoot root =
    let
        center =
            [ ( "center", encodePoint root.center ) ]

        color =
            case root.color of
                Just color ->
                    [ ( "color", encodeColor color ) ]

                Nothing ->
                    []

        radius =
            [ ( "radius", Encode.float root.radius ) ]
    in
        object <|
            center
                ++ color
                ++ radius
