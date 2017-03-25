module Domain.Decoders.Definitions exposing (..)

-- Schema for common types

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
        |> required "x" float
        |> required "y" float
