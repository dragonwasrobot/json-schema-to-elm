defmodule JS2ETest.Printer.AnyOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{AnyOfType, ObjectType, TypeReference, SchemaDefinition}
  alias JS2E.Printer.AnyOfPrinter

  test "print 'any of' type value" do
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
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "shape", "0"], ["#", "shape", "1"]]
      }
      |> AnyOfPrinter.print_type(schema_def, %{}, module_name)

    expected_any_of_type_program = """
    type alias Shape =
        { square : Maybe Square
        , circle : Maybe Circle
        }
    """

    any_of_type_program = result.printed_schema

    assert any_of_type_program == expected_any_of_type_program
  end

  test "print 'any of' decoder" do
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
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> AnyOfPrinter.print_decoder(schema_def, %{}, module_name)

    expected_any_of_decoder_program = """
    shapeDecoder : Decoder Shape
    shapeDecoder =
        decode Shape
            |> optional "square" (nullable squareDecoder) Nothing
            |> optional "circle" (nullable circleDecoder) Nothing
    """

    any_of_decoder_program = result.printed_schema

    assert any_of_decoder_program == expected_any_of_decoder_program
  end

  test "print 'any of' encoder" do
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
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"], ["#", "definitions", "circle"]]
      }
      |> AnyOfPrinter.print_encoder(schema_def, %{}, module_name)

    expected_any_of_encoder_program = """
    encodeShape : Shape -> Value
    encodeShape shape =
        let
            square =
                case shape.square of
                    Just square ->
                        encodeSquare square

                    Nothing ->
                        []

            circle =
                case shape.circle of
                    Just circle ->
                        encodeCircle circle

                    Nothing ->
                        []
        in
            object <|
                square ++ circle
    """

    any_of_encoder_program = result.printed_schema

    assert any_of_encoder_program == expected_any_of_encoder_program
  end
end
