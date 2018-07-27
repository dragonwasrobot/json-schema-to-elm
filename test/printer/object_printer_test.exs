defmodule JS2ETest.Printer.ObjectPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.ObjectPrinter
  alias Types.{EnumType, ObjectType, PrimitiveType, SchemaDefinition}

  test "print object type" do
    result =
      object_type()
      |> ObjectPrinter.print_type(schema_def(), %{}, module_name())

    expected_object_type_program = """
    type alias Circle =
        { color : Color
        , radius : Float
        , title : Maybe String
        }
    """

    object_type_program = result.printed_schema

    assert object_type_program == expected_object_type_program
  end

  test "print object decoder" do
    result =
      object_type()
      |> ObjectPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_object_decoder_program = """
    circleDecoder : Decoder Circle
    circleDecoder =
        succeed Circle
            |> required "color" colorDecoder
            |> required "radius" Decode.float
            |> optional "title" (nullable Decode.string) Nothing
    """

    object_decoder_program = result.printed_schema

    assert object_decoder_program == expected_object_decoder_program
  end

  test "print object encoder" do
    result =
      object_type()
      |> ObjectPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_object_encoder_program = """
    encodeCircle : Circle -> Value
    encodeCircle circle =
        []
            |> encodeRequired "color" circle.color encodeColor
            |> encodeRequired "radius" circle.radius Encode.float
            |> encodeOptional "title" circle.title Encode.string
            |> Encode.object
    """

    object_encoder_program = result.printed_schema

    assert object_encoder_program == expected_object_encoder_program
  end

  test "print object fuzzer" do
    result =
      object_type()
      |> ObjectPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_object_fuzzer = """
    circleFuzzer : Fuzzer Circle
    circleFuzzer =
        Fuzz.map3
            Circle
            colorFuzzer
            Fuzz.float
            (Fuzz.maybe Fuzz.string)


    encodeDecodeCircleTest : Test
    encodeDecodeCircleTest =
        fuzz circleFuzzer "can encode and decode Circle object" <|
            \\circle ->
                circle
                    |> encodeCircle
                    |> Decode.decodeValue circleDecoder
                    |> Expect.equal (Ok circle)
    """

    object_fuzzer = result.printed_schema

    assert object_fuzzer == expected_object_fuzzer
  end

  defp module_name, do: "Domain"

  defp type_dict,
    do: %{
      "#/properties/color" => %EnumType{
        name: "color",
        path: ["#", "properties", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]
      },
      "#/properties/title" => %PrimitiveType{
        name: "title",
        path: ["#", "properties", "title"],
        type: "string"
      },
      "#/properties/radius" => %PrimitiveType{
        name: "radius",
        path: ["#", "properties", "radius"],
        type: "number"
      }
    }

  defp schema_def,
    do: %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict()
    }

  defp object_type,
    do: %ObjectType{
      name: "circle",
      path: ["#"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "properties", "color"],
        "title" => ["#", "properties", "title"],
        "radius" => ["#", "properties", "radius"]
      }
    }
end
