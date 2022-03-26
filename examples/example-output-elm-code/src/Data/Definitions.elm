module Data.Definitions exposing (..)

-- Schema for common types

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
