defmodule JS2ETest.Printer.ExternalReferences do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types

  alias Types.{
    EnumType,
    ObjectType,
    PrimitiveType,
    SchemaDefinition,
    TypeReference
  }

  test "prints external references in generated code" do
    schema_result = Printer.print_schemas(schema_representations(), module_name())

    file_dict = schema_result.file_dict

    encode_program = file_dict["./js2e_output/src/Data/Encode.elm"]

    assert encode_program ==
             """
             module Data.Encode exposing (optional, required)

             -- Helper functions for encoding JSON objects.

             import Json.Encode as Encode exposing (Value)


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
             """

    circle_program = file_dict["./js2e_output/src/Data/Circle.elm"]

    assert circle_program ==
             """
             module Data.Circle exposing (..)

             -- Schema for a circle shape

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
             import Data.Definitions as Definitions


             type alias Circle =
                 { center : Definitions.Point
                 , color : Maybe Definitions.Color
                 , radius : Float
                 }


             circleDecoder : Decoder Circle
             circleDecoder =
                 Decode.succeed Circle
                     |> required "center" Definitions.pointDecoder
                     |> optional "color" (Decode.nullable Definitions.colorDecoder) Nothing
                     |> required "radius" Decode.float


             encodeCircle : Circle -> Value
             encodeCircle circle =
                 []
                     |> Encode.required "center" circle.center Definitions.encodePoint
                     |> Encode.optional "color" circle.color Definitions.encodeColor
                     |> Encode.required "radius" circle.radius Encode.float
                     |> Encode.object
             """

    definitions_program = file_dict["./js2e_output/src/Data/Definitions.elm"]

    assert definitions_program ==
             """
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
             """
  end

  test "prints external references in generated tests" do
    schema_tests_result = Printer.print_schemas_tests(schema_representations(), module_name())

    file_dict = schema_tests_result.file_dict
    circle_tests = file_dict["./js2e_output/tests/Data/CircleTests.elm"]

    assert circle_tests ==
             """
             module Data.CircleTests exposing (..)

             -- Tests: Schema for a circle shape

             import Expect exposing (Expectation)
             import Fuzz exposing (Fuzzer)
             import Test exposing (..)
             import Json.Decode as Decode
             import Data.Circle exposing (..)
             import Data.DefinitionsTests as Definitions


             circleFuzzer : Fuzzer Circle
             circleFuzzer =
                 Fuzz.map3
                     Circle
                     Definitions.pointFuzzer
                     (Fuzz.maybe Definitions.colorFuzzer)
                     Fuzz.float


             encodeDecodeCircleTest : Test
             encodeDecodeCircleTest =
                 fuzz circleFuzzer "can encode and decode Circle object" <|
                     \\circle ->
                         circle
                             |> encodeCircle
                             |> Decode.decodeValue circleDecoder
                             |> Expect.equal (Ok circle)
             """

    definitions_tests = file_dict["./js2e_output/tests/Data/DefinitionsTests.elm"]

    assert definitions_tests ==
             """
             module Data.DefinitionsTests exposing (..)

             -- Tests: Schema for common types

             import Expect exposing (Expectation)
             import Fuzz exposing (Fuzzer)
             import Test exposing (..)
             import Json.Decode as Decode
             import Data.Definitions exposing (..)


             colorFuzzer : Fuzzer Color
             colorFuzzer =
                 Fuzz.oneOf
                     [ Fuzz.constant Red
                     , Fuzz.constant Yellow
                     , Fuzz.constant Green
                     , Fuzz.constant Blue
                     ]


             encodeDecodeColorTest : Test
             encodeDecodeColorTest =
                 fuzz colorFuzzer "can encode and decode Color" <|
                     \\color ->
                         color
                             |> encodeColor
                             |> Decode.decodeValue colorDecoder
                             |> Expect.equal (Ok color)


             pointFuzzer : Fuzzer Point
             pointFuzzer =
                 Fuzz.map2
                     Point
                     Fuzz.float
                     Fuzz.float


             encodeDecodePointTest : Test
             encodeDecodePointTest =
                 fuzz pointFuzzer "can encode and decode Point object" <|
                     \\point ->
                         point
                             |> encodePoint
                             |> Decode.decodeValue pointDecoder
                             |> Expect.equal (Ok point)
             """
  end

  defp module_name, do: "Data"
  defp definitions_schema_id, do: "http://example.com/definitions.json"
  defp circle_schema_id, do: "http://example.com/circle.json"

  defp schema_representations,
    do: %{
      definitions_schema_id() => %SchemaDefinition{
        description: "Schema for common types",
        id: URI.parse(definitions_schema_id()),
        file_path: "definitions.json",
        title: "Definitions",
        types: %{
          "#/definitions/color" => %EnumType{
            name: "color",
            path: URI.parse("#/definitions/color"),
            type: :string,
            values: ["red", "yellow", "green", "blue"]
          },
          "#/definitions/point" => %ObjectType{
            name: "point",
            path: URI.parse("#/definitions/point"),
            properties: %{
              "x" => URI.parse("#/definitions/point/x"),
              "y" => URI.parse("#/definitions/point/y")
            },
            pattern_properties: %{},
            required: ["x", "y"]
          },
          "#/definitions/point/x" => %PrimitiveType{
            name: "x",
            path: URI.parse("#/definitions/point/x"),
            type: :number
          },
          "#/definitions/point/y" => %PrimitiveType{
            name: "y",
            path: URI.parse("#/definitions/point/y"),
            type: :number
          },
          "http://example.com/definitions.json#color" => %EnumType{
            name: "color",
            path: URI.parse("#/definitions/color"),
            type: :string,
            values: ["red", "yellow", "green", "blue"]
          },
          "http://example.com/definitions.json#point" => %ObjectType{
            name: "point",
            path: URI.parse("#/definitions/point"),
            properties: %{
              "x" => URI.parse("#/definitions/point/x"),
              "y" => URI.parse("#/definitions/point/y")
            },
            pattern_properties: %{},
            required: ["x", "y"]
          }
        }
      },
      circle_schema_id() => %SchemaDefinition{
        id: URI.parse(circle_schema_id()),
        file_path: "circle.json",
        title: "Circle",
        description: "Schema for a circle shape",
        types: %{
          "#" => %ObjectType{
            name: "circle",
            path: URI.parse("#"),
            properties: %{
              "center" => URI.parse("#/center"),
              "color" => URI.parse("#/color"),
              "radius" => URI.parse("#/radius")
            },
            pattern_properties: %{},
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
            path: URI.parse("#/radius"),
            type: :number
          },
          "http://example.com/circle.json#" => %ObjectType{
            name: "circle",
            path: URI.parse("#"),
            properties: %{
              "center" => URI.parse("#/center"),
              "color" => URI.parse("#/color"),
              "radius" => URI.parse("#/radius")
            },
            pattern_properties: %{},
            required: ["center", "radius"]
          }
        }
      }
    }
end
