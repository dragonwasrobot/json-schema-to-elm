defmodule JS2ETest.Printer.ArrayPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.ArrayPrinter
  alias Types.{ArrayType, EnumType, PrimitiveType, SchemaDefinition}

  # Array with primitive type

  test "print array primitive type" do
    result =
      array_type_primitive()
      |> ArrayPrinter.print_type(schema_def(), %{}, module_name())

    expected_array_type_program = ""
    array_type_program = result.printed_schema

    assert array_type_program == expected_array_type_program
  end

  test "print array primitive decoder" do
    result =
      array_type_primitive()
      |> ArrayPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_array_decoder_program = """
    namesDecoder : Decoder (List String)
    namesDecoder =
        Decode.list Decode.string
    """

    array_decoder_program = result.printed_schema

    assert array_decoder_program == expected_array_decoder_program
  end

  test "print array primitive encoder" do
    result =
      array_type_primitive()
      |> ArrayPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_array_encoder_program = """
    encodeNames : List String -> Value
    encodeNames names =
        names
            |> Encode.list Encode.string
    """

    array_encoder_program = result.printed_schema

    assert array_encoder_program == expected_array_encoder_program
  end

  test "print array primitive fuzzer" do
    result =
      array_type_primitive()
      |> ArrayPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_array_fuzzer = """
    namesFuzzer : Fuzzer (List String)
    namesFuzzer =
        Fuzz.list Fuzz.string


    encodeDecodeNamesTest : Test
    encodeDecodeNamesTest =
        fuzz namesFuzzer "can encode and decode Names" <|
            \\names ->
                names
                    |> encodeNames
                    |> Decode.decodeValue namesDecoder
                    |> Expect.equal (Ok names)
    """

    array_fuzzer = result.printed_schema

    assert array_fuzzer == expected_array_fuzzer
  end

  # Array with enum type

  test "print array object type" do
    result =
      array_type_object()
      |> ArrayPrinter.print_type(schema_def(), %{}, module_name())

    expected_array_type_program = ""
    array_type_program = result.printed_schema

    assert array_type_program == expected_array_type_program
  end

  test "print array object decoder" do
    result =
      array_type_object()
      |> ArrayPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_array_decoder_program = """
    colorsDecoder : Decoder (List Color)
    colorsDecoder =
        Decode.list colorDecoder
    """

    array_decoder_program = result.printed_schema

    assert array_decoder_program == expected_array_decoder_program
  end

  test "print array object encoder" do
    result =
      array_type_object()
      |> ArrayPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_array_encoder_program = """
    encodeColors : List Color -> Value
    encodeColors colors =
        colors
            |> Encode.list encodeColor
    """

    array_encoder_program = result.printed_schema

    assert array_encoder_program == expected_array_encoder_program
  end

  test "print array object fuzzer" do
    result =
      array_type_object()
      |> ArrayPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_array_fuzzer = """
    colorsFuzzer : Fuzzer (List Color)
    colorsFuzzer =
        Fuzz.list colorFuzzer


    encodeDecodeColorsTest : Test
    encodeDecodeColorsTest =
        fuzz colorsFuzzer "can encode and decode Colors" <|
            \\colors ->
                colors
                    |> encodeColors
                    |> Decode.decodeValue colorsDecoder
                    |> Expect.equal (Ok colors)
    """

    array_fuzzer = result.printed_schema

    assert array_fuzzer == expected_array_fuzzer
  end

  defp module_name, do: "Domain"

  defp array_type_primitive do
    %ArrayType{
      name: "names",
      path: URI.parse("#/names"),
      items: URI.parse("#/names/items")
    }
  end

  defp array_type_object do
    %ArrayType{
      name: "colors",
      path: URI.parse("#/colors"),
      items: URI.parse("#/colors/items")
    }
  end

  defp schema_def do
    %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      file_path: "test.json",
      title: "Test",
      types: type_dict()
    }
  end

  defp type_dict do
    %{
      "#/names/items" => %PrimitiveType{
        name: :anonymous,
        description: nil,
        default: nil,
        path: URI.parse("#/names/items"),
        type: :string
      },
      "#/colors/items" => %EnumType{
        name: "color",
        path: URI.parse("#/definitions/color"),
        type: "string",
        values: ["none", "green", "yellow", "red"]
      }
    }
  end
end
