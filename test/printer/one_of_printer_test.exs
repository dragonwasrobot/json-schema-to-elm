defmodule JS2ETest.Printer.OneOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{OneOfType, ObjectType, TypeReference, SchemaDefinition}
  alias JS2E.Printer.OneOfPrinter

  test "print 'one of' type value" do
    module_name = "Domain"

    type_dict = %{
      "#/shape/0" => %TypeReference{
        name: "square",
        path: ["#", "definitions", "square"]
      },
      "#/shape/1" => %TypeReference{
        name: "circle",
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
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "shape", "0"], ["#", "shape", "1"]]
      }
      |> OneOfPrinter.print_type(schema_def, %{}, module_name)

    expected_one_of_type_program = """
    type Shape
        = ShapeSq Square
        | ShapeCi Circle
    """

    one_of_type_program = result.printed_schema

    assert one_of_type_program == expected_one_of_type_program
  end

  test "print 'one of' decoder" do
    module_name = "Domain"

    type_dict = %{
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
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> OneOfPrinter.print_decoder(schema_def, %{}, module_name)

    expected_one_of_decoder_program = """
    shapeDecoder : Decoder Shape
    shapeDecoder =
        oneOf [ squareDecoder |> andThen (succeed << ShapeSq)
              , circleDecoder |> andThen (succeed << ShapeCi)
              ]
    """

    one_of_decoder_program = result.printed_schema

    assert one_of_decoder_program == expected_one_of_decoder_program
  end

  test "print 'one of' encoder" do
    module_name = "Domain"

    type_dict = %{
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
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> OneOfPrinter.print_encoder(schema_def, %{}, module_name)

    expected_one_of_encoder_program = """
    encodeShape : Shape -> Value
    encodeShape shape =
        case shape of
            ShapeSq square ->
                encodeSquare square

            ShapeCi circle ->
                encodeCircle circle
    """

    one_of_encoder_program = result.printed_schema

    assert one_of_encoder_program == expected_one_of_encoder_program
  end
end
