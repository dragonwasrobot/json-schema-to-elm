defmodule JS2ETest.Printers.ExternalReferences do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer

  alias JS2E.Types.{
    EnumType,
    ObjectType,
    PrimitiveType,
    TypeReference,
    SchemaDefinition
  }

  test "print external references" do
    module_name = "Data"

    definitions_schema_id = "http://example.com/definitions.json"
    circle_schema_id = "http://example.com/circle.json"

    schema_representations = %{
      definitions_schema_id => %SchemaDefinition{
        description: "Schema for common types",
        id: URI.parse(definitions_schema_id),
        title: "Definitions",
        types: %{
          "#/definitions/color" => %EnumType{
            name: "color",
            path: ["#", "definitions", "color"],
            type: "string",
            values: ["red", "yellow", "green", "blue"]
          },
          "#/definitions/point" => %ObjectType{
            name: "point",
            path: ["#", "definitions", "point"],
            properties: %{
              "x" => ["#", "definitions", "point", "x"],
              "y" => ["#", "definitions", "point", "y"]
            },
            required: ["x", "y"]
          },
          "#/definitions/point/x" => %PrimitiveType{
            name: "x",
            path: ["#", "definitions", "point", "x"],
            type: "number"
          },
          "#/definitions/point/y" => %PrimitiveType{
            name: "y",
            path: ["#", "definitions", "point", "y"],
            type: "number"
          },
          "http://example.com/definitions.json#color" => %EnumType{
            name: "color",
            path: ["#", "definitions", "color"],
            type: "string",
            values: ["red", "yellow", "green", "blue"]
          },
          "http://example.com/definitions.json#point" => %ObjectType{
            name: "point",
            path: ["#", "definitions", "point"],
            properties: %{
              "x" => ["#", "definitions", "point", "x"],
              "y" => ["#", "definitions", "point", "y"]
            },
            required: ["x", "y"]
          }
        }
      },
      circle_schema_id => %SchemaDefinition{
        id: URI.parse(circle_schema_id),
        title: "Circle",
        description: "Schema for a circle shape",
        types: %{
          "#" => %ObjectType{
            name: "circle",
            path: ["#"],
            properties: %{
              "center" => ["#", "center"],
              "color" => ["#", "color"],
              "radius" => ["#", "radius"]
            },
            required: ["center", "radius"]
          },
          "#/center" => %TypeReference{
            name: "center",
            path: URI.parse("http://example.com/definitions.json#point")
          },
          "#/color" => %TypeReference{
            name: "color",
            path: URI.parse("http://example.com/definitions.json#color")
          },
          "#/radius" => %PrimitiveType{
            name: "radius",
            path: ["#", "radius"],
            type: "number"
          },
          "http://example.com/circle.json#" => %ObjectType{
            name: "circle",
            path: "#",
            properties: %{
              "center" => ["#", "center"],
              "color" => ["#", "color"],
              "radius" => ["#", "radius"]
            },
            required: ["center", "radius"]
          }
        }
      }
    }

    schema_result = Printer.print_schemas(schema_representations, module_name)

    file_dict = schema_result.file_dict
    circle_program = file_dict["./Data/Circle.elm"]

    assert circle_program ==
             """
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
             """

    definitions_program = file_dict["./Data/Definitions.elm"]

    assert definitions_program ==
             """
             module Data.Definitions exposing (..)

             -- Schema for common types

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
                 let
                     x =
                         [ ( "x", Encode.float point.x ) ]

                     y =
                         [ ( "y", Encode.float point.y ) ]
                 in
                     object <|
                         x ++ y
             """
  end
end
