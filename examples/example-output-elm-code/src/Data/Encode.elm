module Data.Encode
    exposing
        ( nestedOptional
        , nestedRequired
        , optional
        , required
        )

-- Helper functions for encoding JSON objects.

import Json.Encode as Encode exposing (Value)


nestedRequired :
    String
    -> Maybe a
    -> (a -> b)
    -> (b -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
nestedRequired key maybeData getValue encode properties =
    case maybeData of
        Just data ->
            properties |> required key (getValue data) encode

        Nothing ->
            properties


nestedOptional :
    String
    -> Maybe a
    -> (a -> Maybe b)
    -> (b -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
nestedOptional key maybeData getValue encode properties =
    case maybeData of
        Just data ->
            properties |> optional key (getValue data) encode

        Nothing ->
            properties


required :
    String
    -> a
    -> (a -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
required key value encode properties =
    properties ++ [ ( key, encode value ) ]


optional :
    String
    -> Maybe a
    -> (a -> Value)
    -> List ( String, Value )
    -> List ( String, Value )
optional key maybe encode properties =
    case maybe of
        Just value ->
            properties ++ [ ( key, encode value ) ]

        Nothing ->
            properties
