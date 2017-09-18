defmodule JS2ETest.Printers.TuplePrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{TupleType, ObjectType, TypeReference, SchemaDefinition}
  alias JS2E.Printers.TuplePrinter

  test "print 'tuple' type value" do

    type_dict = %{
      "#/shapePair/0" =>
      %TypeReference{name: "square",
                     path: ["#", "definitions", "square"]},

      "#/shapePair/1" =>
        %TypeReference{name: "circle",
                       path: ["#", "definitions", "circle"]},

      "#/definitions/square" =>
        %ObjectType{name: "square",
                    path: ["#"],
                    required: ["color", "size"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      module: "Domain",
      types: type_dict}

    tuple_type_program =
      %TupleType{
        name: "shapePair",
        path: ["#", "definitions", "shapePair"],
        items: [["#", "shapePair", "0"],
                ["#", "shapePair", "1"]]
      }
      |> TuplePrinter.print_type(schema_def, %{})

    expected_tuple_type_program =
      """
      type alias ShapePair =
          ( Square
          , Circle
          )
      """

    assert tuple_type_program == expected_tuple_type_program
  end

  test "print 'tuple' decoder" do

    type_dict = %{
      "#/definitions/square" =>
      %ObjectType{name: "square",
                  path: ["#"],
                  required: ["color", "size"],
                  properties: %{"color" => ["#", "properties", "color"],
                                "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      module: "Domain",
      types: type_dict}

    tuple_decoder_program =
      %TupleType{
        name: "shapePair",
        path: ["#", "definitions", "shapePair"],
        items: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> TuplePrinter.print_decoder(schema_def, %{})

    expected_tuple_decoder_program =
    """
    shapePairDecoder : Decoder ShapePair
    shapePairDecoder =
        map2 ShapePair
            (index 0 squareDecoder)
            (index 1 circleDecoder)
    """

    assert tuple_decoder_program == expected_tuple_decoder_program
  end

  test "print 'tuple' encoder" do

    type_dict = %{
      "#/definitions/square" =>
      %ObjectType{name: "square",
                  path: ["#"],
                  required: ["color", "size"],
                  properties: %{"color" => ["#", "properties", "color"],
                                "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      module: "Domain",
      types: type_dict}

    tuple_encoder_program =
      %TupleType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        items: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> TuplePrinter.print_encoder(schema_def, %{})

    expected_tuple_encoder_program =
    """
    encodeShape : Shape -> Value
    encodeShape shape =
        let
            square =
                encodeSquare shape.square

            circle =
                encodeCircle shape.circle
        in
            list (square, circle)
    """

    assert tuple_encoder_program == expected_tuple_encoder_program
  end

end
