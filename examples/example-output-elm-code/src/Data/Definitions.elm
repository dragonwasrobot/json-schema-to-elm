module Data.Definitions exposing (..)

-- Schema for common types

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
import Data.Utils
    exposing
        ( encodeNestedOptional
        , encodeNestedRequired
        , encodeOptional
        , encodeRequired
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


colorDecoder : Decoder Color
colorDecoder =
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
    succeed Point
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
    []
        |> encodeRequired "x" point.x Encode.float
        |> encodeRequired "y" point.y Encode.float
        |> Encode.object
