defmodule JS2ETest.Printer.ObjectPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.ObjectPrinter
  alias Types.{ArrayType, EnumType, ObjectType, PrimitiveType, SchemaDefinition}

  test "print object type" do
    result =
      object_type()
      |> ObjectPrinter.print_type(schema_def(), %{}, module_name())

    expected_object_type_program = """
    type alias Circle =
        { color : Color
        , radius : Float
        , tags : List String
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
        Decode.succeed Circle
            |> required "color" colorDecoder
            |> required "radius" Decode.float
            |> required "tags" tagsDecoder
            |> optional "title" (Decode.nullable Decode.string) Nothing
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
            |> Encode.required "color" circle.color encodeColor
            |> Encode.required "radius" circle.radius Encode.float
            |> Encode.required "tags" circle.tags encodeTags
            |> Encode.optional "title" circle.title Encode.string
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
        Fuzz.map4
            Circle
            colorFuzzer
            Fuzz.float
            tagsFuzzer
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
        path: URI.parse("#/properties/color"),
        type: "string",
        values: ["none", "green", "yellow", "red"]
      },
      "#/properties/title" => %PrimitiveType{
        name: "title",
        path: URI.parse("#/properties/title"),
        type: "string"
      },
      "#/properties/radius" => %PrimitiveType{
        name: "radius",
        path: URI.parse("#/properties/radius"),
        type: "number"
      },
      "#/properties/tags" => %ArrayType{
        name: "tags",
        path: URI.parse("#/properties/tags"),
        items: URI.parse("#/properties/tags/items")
      },
      "#/properties/tags/items" => %PrimitiveType{
        name: "items",
        path: URI.parse("#/properties/radius/items"),
        type: "string"
      }
    }

  defp schema_def,
    do: %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      file_path: "test.json",
      title: "Test",
      types: type_dict()
    }

  defp object_type,
    do: %ObjectType{
      name: "circle",
      path: URI.parse("#"),
      required: ["color", "radius", "tags"],
      properties: %{
        "color" => URI.parse("#/properties/color"),
        "title" => URI.parse("#/properties/title"),
        "radius" => URI.parse("#/properties/radius"),
        "tags" => URI.parse("#/properties/tags")
      },
      pattern_properties: %{}
    }
end
