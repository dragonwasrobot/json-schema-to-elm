defmodule JS2ETest.Printers.AllOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{AllOfType, ObjectType, TypeReference, SchemaDefinition}
  alias JS2E.Printers.AllOfPrinter

  test "print 'all of' type value" do
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
      %AllOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "shape", "0"], ["#", "shape", "1"]]
      }
      |> AllOfPrinter.print_type(schema_def, %{}, module_name)

    all_of_type_program = result.printed_schema

    expected_all_of_type_program = """
    type alias Shape =
        { square : Square
        , circle : Circle
        }
    """

    assert all_of_type_program == expected_all_of_type_program
  end

  test "print 'all of' decoder" do
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
      %AllOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> AllOfPrinter.print_decoder(schema_def, %{}, module_name)

    expected_all_of_decoder_program = """
    shapeDecoder : Decoder Shape
    shapeDecoder =
        decode Shape
            |> required "square" squareDecoder
            |> required "circle" circleDecoder
    """

    all_of_decoder_program = result.printed_schema

    assert all_of_decoder_program == expected_all_of_decoder_program
  end

  test "print 'all of' encoder" do
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
      %AllOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> AllOfPrinter.print_encoder(schema_def, %{}, module_name)

    expected_all_of_encoder_program = """
    encodeShape : Shape -> Value
    encodeShape shape =
        let
            square =
                encodeSquare shape.square

            circle =
                encodeCircle shape.circle
        in
            object <|
                square ++ circle
    """

    all_of_encoder_program = result.printed_schema

    assert all_of_encoder_program == expected_all_of_encoder_program
  end
end
