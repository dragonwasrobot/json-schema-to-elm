module Data.Utils
    exposing
        ( encodeNestedOptional
        , encodeNestedRequired
        , encodeOptional
        , encodeRequired
        )

-- Util functions for decoding and encoding JSON objects.

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


encodeNestedRequired :
    String
    -> Maybe a
    -> (a -> b)
    -> (b -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
encodeNestedRequired key maybeData getValue encode properties =
    case maybeData of
        Just data ->
            properties |> encodeRequired key (getValue data) encode

        Nothing ->
            properties


encodeNestedOptional :
    String
    -> Maybe a
    -> (a -> Maybe b)
    -> (b -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
encodeNestedOptional key maybeData getValue encode properties =
    case maybeData of
        Just data ->
            properties |> encodeOptional key (getValue data) encode

        Nothing ->
            properties


encodeRequired :
    String
    -> a
    -> (a -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
encodeRequired key value encode properties =
    properties ++ [ ( key, encode value ) ]


encodeOptional :
    String
    -> Maybe a
    -> (a -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
encodeOptional key maybe encode properties =
    case maybe of
        Just value ->
            properties ++ [ ( key, encode value ) ]

        Nothing ->
            properties
