defmodule JS2ETest.Printers.ExternalReferences do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JS2E.Types.{EnumType, ObjectType, PrimitiveType,
                    TypeReference, SchemaDefinition}

  test "print external references" do

    schema_representations = %{

      "http://example.com/definitions.json" =>
      %SchemaDefinition{
        description: "Schema for common types",
        id: URI.parse("http://example.com/definitions.json"),
        title: "Definitions",
        types: %{

          "#/definitions/color" =>
          %EnumType{name: "color",
                    path: ["#", "definitions", "color"],
                    type: "string",
                    values: ["red", "yellow", "green", "blue"]},

          "#/definitions/point" =>
            %ObjectType{name: "point",
                        path: ["#", "definitions", "point"],
                        properties: %{
                          "x" => ["#", "definitions", "point", "x"],
                          "y" => ["#", "definitions", "point", "y"]},
                        required: ["x", "y"]},

          "#/definitions/point/x" =>
            %PrimitiveType{name: "x",
                           path: ["#", "definitions", "point", "x"],
                           type: "number"},

          "#/definitions/point/y" =>
            %PrimitiveType{name: "y",
                           path: ["#", "definitions", "point", "y"],
                           type: "number"},

          "http://example.com/definitions.json#color" =>
            %EnumType{name: "color",
                      path: ["#", "definitions", "color"],
                      type: "string",
                      values: ["red", "yellow", "green", "blue"]},

          "http://example.com/definitions.json#point" =>
            %ObjectType{name: "point",
                        path: ["#", "definitions", "point"],
                        properties: %{
                          "x" => ["#", "definitions", "point", "x"],
                          "y" => ["#", "definitions", "point", "y"]},
                        required: ["x", "y"]}
        }
      },

      "http://example.com/circle.json" =>
        %SchemaDefinition{
          id: URI.parse("http://example.com/circle.json"),
          title: "Circle",
          description: "Schema for a circle shape",
          types: %{

            "#" =>
            %ObjectType{name: "circle",
                        path: ["#"],
                        properties: %{
                          "center" => ["#", "center"],
                          "color" => ["#", "color"],
                          "radius" => ["#", "radius"]},
                        required: []},

            "#/center" =>
              %TypeReference{
                name: "center",
                path: URI.parse("http://example.com/definitions.json#point")},

            "#/color" =>
              %TypeReference{
                name: "color",
                path: URI.parse("http://example.com/definitions.json#color")},

            "#/radius" =>
              %PrimitiveType{name: "radius",
                             path: ["#", "radius"],
                             type: "number"},

            "http://example.com/circle.json#" =>
              %ObjectType{name: "circle",
                          path: "#",
                          properties: %{
                            "center" => ["#", "center"],
                            "color" => ["#", "color"],
                            "radius" => ["#", "radius"]},
                          required: []}
          }
        }
    }

    module_prefix = "Domain"
    elm_decoder_program = Printer.print_schemas(
      schema_representations, module_prefix)

    Logger.debug "#{inspect elm_decoder_program}"

    circle_decoder_program = elm_decoder_program["./Domain/Decoders/Circle.elm"]

    assert circle_decoder_program ==
      """
      module Domain.Decoders.Circle exposing (..)

      -- Schema for a circle shape

      import Json.Decode as Decode
          exposing
              ( int
              , float
              , string
              , succeed
              , fail
              , list
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
      import Domain.Decoders.Definitions
          exposing
              ( Color
              , colorDecoder
              , Point
              , pointDecoder
              )


      type alias Circle =
          { center : Maybe Point
          , color : Maybe Color
          , radius : Maybe Float
          }


      circleDecoder : Decoder Circle
      circleDecoder =
          decode Circle
              |> optional "center" (nullable pointDecoder) Nothing
              |> optional "color" (string |> andThen colorDecoder |> maybe) Nothing
              |> optional "radius" (nullable float) Nothing
      """

    definitions_decoder_program =
      elm_decoder_program["./Domain/Decoders/Definitions.elm"]

    assert definitions_decoder_program ==
      """
      module Domain.Decoders.Definitions exposing (..)

      -- Schema for common types

      import Json.Decode as Decode
          exposing
              ( int
              , float
              , string
              , succeed
              , fail
              , list
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
      """
  end

end
