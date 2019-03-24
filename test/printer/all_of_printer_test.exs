defmodule JS2ETest.Printer.AllOfPrinter do
  use ExUnit.Case
  require Logger
  alias JS2E.Printer.AllOfPrinter

  alias JsonSchema.Types.{
    AllOfType,
    EnumType,
    ObjectType,
    PrimitiveType,
    SchemaDefinition,
    TypeReference
  }

  test "print 'all of' type value" do
    result =
      all_of_type()
      |> AllOfPrinter.print_type(schema_def(), %{}, module_name())

    all_of_type_program = result.printed_schema

    expected_all_of_type_program = """
    type alias FancyCircle =
        { zero : Zero
        , circle : Circle
        }
    """

    assert all_of_type_program == expected_all_of_type_program
  end

  test "print 'all of' decoder" do
    result =
      all_of_type()
      |> AllOfPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_all_of_decoder_program = """
    fancyCircleDecoder : Decoder FancyCircle
    fancyCircleDecoder =
        succeed FancyCircle
            |> custom zeroDecoder
            |> custom circleDecoder
    """

    all_of_decoder_program = result.printed_schema

    assert all_of_decoder_program == expected_all_of_decoder_program
  end

  test "print 'all of' encoder" do
    result =
      all_of_type()
      |> AllOfPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_all_of_encoder_program = """
    encodeFancyCircle : FancyCircle -> Value
    encodeFancyCircle fancyCircle =
        []
            |> encodeRequired "color" fancyCircle.zero.color encodeColor
            |> encodeOptional "description" fancyCircle.zero.description Encode.string
            |> encodeRequired "radius" fancyCircle.circle.radius Encode.float
            |> Encode.object
    """

    all_of_encoder_program = result.printed_schema

    assert all_of_encoder_program == expected_all_of_encoder_program
  end

  test "print 'all of' fuzzer" do
    result =
      all_of_type()
      |> AllOfPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_all_of_fuzzer_program = """
    fancyCircleFuzzer : Fuzzer FancyCircle
    fancyCircleFuzzer =
        Fuzz.map2
            FancyCircle
            zeroFuzzer
            circleFuzzer


    encodeDecodeFancyCircleTest : Test
    encodeDecodeFancyCircleTest =
        fuzz fancyCircleFuzzer "can encode and decode FancyCircle object" <|
            \\fancyCircle ->
                fancyCircle
                    |> encodeFancyCircle
                    |> Decode.decodeValue fancyCircleDecoder
                    |> Expect.equal (Ok fancyCircle)
    """

    all_of_fuzzer_program = result.printed_schema

    assert all_of_fuzzer_program == expected_all_of_fuzzer_program
  end

  defp path, do: "#/definitions/fancyCircle"
  def module_name, do: "Data"

  def all_of_type do
    %AllOfType{
      name: "fancyCircle",
      path: URI.parse(path()),
      types: [
        URI.parse(Path.join(path(), "allOf/0")),
        URI.parse(Path.join(path(), "allOf/1"))
      ]
    }
  end

  def schema_def do
    %SchemaDefinition{
      description: "'allOf' example schema",
      id: URI.parse("http://example.com/all_of_example.json"),
      title: "AllOfExample",
      types: type_dict()
    }
  end

  def type_dict do
    %{
      "#/definitions/fancyCircle/allOf/0" => %ObjectType{
        name: "0",
        path: URI.parse(Path.join(path(), "allOf/0")),
        required: ["color"],
        properties: %{
          "color" => URI.parse(Path.join(path(), "allOf/0/properties/color")),
          "description" => URI.parse(Path.join(path(), "allOf/0/properties/description"))
        }
      },
      "#/definitions/fancyCircle/allOf/0/properties/color" => %TypeReference{
        name: "color",
        path: URI.parse("#/definitions/color")
      },
      "#/definitions/color" => %EnumType{
        name: "color",
        path: URI.parse("#/definitions/color"),
        type: "string",
        values: ["red", "yellow", "green"]
      },
      "#/definitions/fancyCircle/allOf/0/properties/description" => %PrimitiveType{
        name: "description",
        path: URI.parse(Path.join(path(), "allOf/0/properties/description")),
        type: "string"
      },
      "#/definitions/fancyCircle/allOf/1" => %TypeReference{
        name: "1",
        path: URI.parse("#/definitions/circle")
      },
      "#/definitions/circle" => %ObjectType{
        name: "circle",
        path: URI.parse("#/definitions/circle"),
        required: ["radius"],
        properties: %{
          "radius" => URI.parse("#/definitions/circle/properties/radius")
        }
      },
      "#/definitions/circle/properties/radius" => %PrimitiveType{
        name: "radius",
        path: URI.parse("#/definitions/circle/properties/radius"),
        type: "number"
      }
    }
  end
end
