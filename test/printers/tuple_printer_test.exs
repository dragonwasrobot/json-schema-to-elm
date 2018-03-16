defmodule JS2ETest.Printers.TuplePrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{TupleType, ObjectType, TypeReference, SchemaDefinition}
  alias JS2E.Printers.TuplePrinter

  test "print 'tuple' type value" do
    module_name = "Domain"

    type_dict = %{
      "#/shapePair/0" => %TypeReference{
        name: "0",
        path: ["#", "definitions", "square"]
      },
      "#/shapePair/1" => %TypeReference{
        name: "1",
        path: ["#", "definitions", "circle"]
      },
      "#/definitions/square" => %ObjectType{
        name: "square",
        path: ["#"],
        required: ["color", "size"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "size"]
        }
      },
      "#/definitions/circle" => %ObjectType{
        name: "circle",
        path: ["#"],
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "radius" => ["#", "properties", "radius"]
        }
      }
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }

    result =
      %TupleType{
        name: "shapePair",
        path: ["#", "shapePair"],
        items: [["#", "shapePair", "0"], ["#", "shapePair", "1"]]
      }
      |> TuplePrinter.print_type(schema_def, %{}, module_name)

    expected_tuple_type_program = """
    type alias ShapePair =
        ( Square
        , Circle
        )
    """

    tuple_type_program = result.printed_schema

    assert tuple_type_program == expected_tuple_type_program
  end

  test "print 'tuple' decoder" do
    module_name = "Domain"

    type_dict = %{
      "#/shapePair/0" => %TypeReference{
        name: "0",
        path: ["#", "definitions", "square"]
      },
      "#/shapePair/1" => %TypeReference{
        name: "1",
        path: ["#", "definitions", "circle"]
      },
      "#/definitions/square" => %ObjectType{
        name: "square",
        path: ["#"],
        required: ["color", "size"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "size"]
        }
      },
      "#/definitions/circle" => %ObjectType{
        name: "circle",
        path: ["#"],
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "radius" => ["#", "properties", "radius"]
        }
      }
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }

    result =
      %TupleType{
        name: "shapePair",
        path: ["#"],
        items: [["#", "shapePair", "0"], ["#", "shapePair", "1"]]
      }
      |> TuplePrinter.print_decoder(schema_def, %{}, module_name)

    expected_tuple_decoder_program = """
    shapePairDecoder : Decoder ShapePair
    shapePairDecoder =
        Decode.map2 (,)
            (index 0 squareDecoder)
            (index 1 circleDecoder)
    """

    tuple_decoder_program = result.printed_schema

    assert tuple_decoder_program == expected_tuple_decoder_program
  end

  test "print 'tuple' encoder" do
    module_name = "Domain"

    type_dict = %{
      "#/shapePair/0" => %TypeReference{
        name: "0",
        path: ["#", "definitions", "square"]
      },
      "#/shapePair/1" => %TypeReference{
        name: "1",
        path: ["#", "definitions", "circle"]
      },
      "#/definitions/square" => %ObjectType{
        name: "square",
        path: ["#"],
        required: ["color", "size"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "size"]
        }
      },
      "#/definitions/circle" => %ObjectType{
        name: "circle",
        path: ["#"],
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "radius" => ["#", "properties", "radius"]
        }
      }
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }

    result =
      %TupleType{
        name: "shapePair",
        path: ["#"],
        items: [["#", "shapePair", "0"], ["#", "shapePair", "1"]]
      }
      |> TuplePrinter.print_encoder(schema_def, %{}, module_name)

    expected_tuple_encoder_program = """
    encodeShapePair : ShapePair -> Value
    encodeShapePair (square, circle) =
        let
            encodedsquare =
                encodeSquare square

            encodedcircle =
                encodeCircle circle
        in
            list [encodedsquare, encodedcircle]
    """

    tuple_encoder_program = result.printed_schema

    assert tuple_encoder_program == expected_tuple_encoder_program
  end
end
