defmodule JS2ETest.Printer.OneOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.OneOfPrinter
  alias Types.{ObjectType, OneOfType, SchemaDefinition, TypeReference}

  test "print 'one of' type value" do
    result =
      one_of_type()
      |> OneOfPrinter.print_type(schema_def(), %{}, module_name())

    expected_one_of_type_program = """
    type Shape
        = ShapeSq Square
        | ShapeCi Circle
    """

    one_of_type_program = result.printed_schema

    assert one_of_type_program == expected_one_of_type_program
  end

  test "print 'one of' decoder" do
    result =
      one_of_type()
      |> OneOfPrinter.print_decoder(schema_def(), %{}, module_name())

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
    result =
      one_of_type()
      |> OneOfPrinter.print_encoder(schema_def(), %{}, module_name())

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

  test "print 'one of' fuzzer" do
    result =
      one_of_type()
      |> OneOfPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_one_of_fuzzer_program = """
    shapeFuzzer : Fuzzer Shape
    shapeFuzzer =
        Fuzz.oneOf
            [ squareFuzzer
            , circleFuzzer
            ]


    encodeDecodeShapeTest : Test
    encodeDecodeShapeTest =
        fuzz shapeFuzzer "can encode and decode Shape object" <|
            \\shape ->
                shape
                    |> encodeShape
                    |> Decode.decodeValue shapeDecoder
                    |> Expect.equal (Ok shape)
    """

    one_of_fuzzer_program = result.printed_schema

    assert one_of_fuzzer_program == expected_one_of_fuzzer_program
  end

  defp module_name, do: "Domain"

  defp one_of_type,
    do: %OneOfType{
      name: "shape",
      path: ["#", "definitions", "shape"],
      types: [
        ["#", "shape", "oneOf", "0"],
        ["#", "shape", "oneOf", "1"]
      ]
    }

  defp schema_def,
    do: %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict()
    }

  defp type_dict,
    do: %{
      "#/shape/oneOf/0" => %TypeReference{
        name: "square",
        path: ["#", "definitions", "square"]
      },
      "#/shape/oneOf/1" => %TypeReference{
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
end
