defmodule JS2ETest.Printer.AnyOfPrinter do
  use ExUnit.Case
  require Logger
  alias JS2E.Printer.AnyOfPrinter

  alias JsonSchema.Types.{
    AnyOfType,
    EnumType,
    ObjectType,
    PrimitiveType,
    SchemaDefinition,
    TypeReference
  }

  test "print 'any of' type value" do
    result =
      any_of_type()
      |> AnyOfPrinter.print_type(schema_def(), %{}, module_name())

    any_of_type_program = result.printed_schema

    expected_any_of_type_program = """
    type alias FancyCircle =
        { zero : Maybe Zero
        , circle : Maybe Circle
        }
    """

    assert any_of_type_program == expected_any_of_type_program
  end

  test "print 'any of' decoder" do
    result =
      any_of_type()
      |> AnyOfPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_any_of_decoder_program = """
    fancyCircleDecoder : Decoder FancyCircle
    fancyCircleDecoder =
        succeed FancyCircle
            |> custom (nullable zeroDecoder)
            |> custom (nullable circleDecoder)
    """

    any_of_decoder_program = result.printed_schema

    assert any_of_decoder_program == expected_any_of_decoder_program
  end

  test "print 'any of' encoder" do
    result =
      any_of_type()
      |> AnyOfPrinter.print_encoder(schema_def(), %{}, module_name())

    any_of_encoder_program = result.printed_schema

    expected_any_of_encoder_program = """
    encodeFancyCircle : FancyCircle -> Value
    encodeFancyCircle fancyCircle =
        []
            |> encodeNestedRequired "color" fancyCircle.zero .color encodeColor
            |> encodeNestedOptional "description" fancyCircle.zero .description Encode.string
            |> encodeNestedRequired "radius" fancyCircle.circle .radius Encode.float
            |> Encode.object
    """

    assert any_of_encoder_program == expected_any_of_encoder_program
  end

  test "print 'any of' fuzzer" do
    result =
      any_of_type()
      |> AnyOfPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_any_of_fuzzer_program = """
    fancyCircleFuzzer : Fuzzer FancyCircle
    fancyCircleFuzzer =
        Fuzz.map2
            FancyCircle
            (Fuzz.maybe zeroFuzzer)
            (Fuzz.maybe circleFuzzer)


    encodeDecodeFancyCircleTest : Test
    encodeDecodeFancyCircleTest =
        fuzz fancyCircleFuzzer "can encode and decode FancyCircle object" <|
            \\fancyCircle ->
                fancyCircle
                    |> encodeFancyCircle
                    |> Decode.decodeValue fancyCircleDecoder
                    |> Expect.equal (Ok fancyCircle)
    """

    any_of_fuzzer_program = result.printed_schema

    assert any_of_fuzzer_program == expected_any_of_fuzzer_program
  end

  def module_name, do: "Data"
  defp path, do: "#/definitions/fancyCircle"

  def any_of_type do
    %AnyOfType{
      name: "fancyCircle",
      path: URI.parse(path()),
      types: [
        URI.parse(Path.join(path(), "anyOf/0")),
        URI.parse(Path.join(path(), "anyOf/1"))
      ]
    }
  end

  def schema_def do
    %SchemaDefinition{
      description: "'anyOf' example schema",
      id: URI.parse("http://example.com/any_of_example.json"),
      file_path: "any_of_example.json",
      title: "AnyOfExample",
      types: type_dict()
    }
  end

  def type_dict do
    %{
      "#/definitions/fancyCircle/anyOf/0" => %ObjectType{
        name: "0",
        path: URI.parse(Path.join(path(), "anyOf/0")),
        required: ["color"],
        properties: %{
          "color" => URI.parse(Path.join(path(), "anyOf/0/properties/color")),
          "description" =>
            URI.parse(Path.join(path(), "anyOf/0/properties/description"))
        },
        pattern_properties: %{}
      },
      "#/definitions/fancyCircle/anyOf/0/properties/color" => %TypeReference{
        name: "color",
        path: URI.parse("#/definitions/color")
      },
      "#/definitions/color" => %EnumType{
        name: "color",
        path: URI.parse("#/definitions/color"),
        type: "string",
        values: ["red", "yellow", "green"]
      },
      "#/definitions/fancyCircle/anyOf/0/properties/description" =>
        %PrimitiveType{
          name: "description",
          path: URI.parse(Path.join(path(), "anyOf/0/properties/description")),
          type: "string"
        },
      "#/definitions/fancyCircle/anyOf/1" => %TypeReference{
        name: "1",
        path: URI.parse("#/definitions/circle")
      },
      "#/definitions/circle" => %ObjectType{
        name: "circle",
        path: URI.parse("#/definitions/circle"),
        required: ["radius"],
        properties: %{
          "radius" => URI.parse("#/definitions/circle/properties/radius")
        },
        pattern_properties: %{}
      },
      "#/definitions/circle/properties/radius" => %PrimitiveType{
        name: "radius",
        path: URI.parse("#/definitions/circle/properties/radius"),
        type: "number"
      }
    }
  end
end
