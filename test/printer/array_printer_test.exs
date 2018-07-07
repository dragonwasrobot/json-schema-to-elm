defmodule JS2ETest.Printer.ArrayPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.{Printer, Types}
  alias Printer.ArrayPrinter
  alias Types.{ArrayType, EnumType, SchemaDefinition}

  test "print array type" do
    result =
      array_type()
      |> ArrayPrinter.print_type(schema_def(), %{}, module_name())

    expected_array_type_program = ""
    array_type_program = result.printed_schema

    assert array_type_program == expected_array_type_program
  end

  test "print array decoder" do
    result =
      array_type()
      |> ArrayPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_array_decoder_program = """
    colorsDecoder : Decoder (List Color)
    colorsDecoder =
        Decode.list colorDecoder
    """

    array_decoder_program = result.printed_schema

    assert array_decoder_program == expected_array_decoder_program
  end

  test "print array encoder" do
    result =
      array_type()
      |> ArrayPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_array_encoder_program = """
    encodeColors : List Color -> Value
    encodeColors colors =
        Encode.list <| List.map encodeColor <| colors
    """

    array_encoder_program = result.printed_schema

    assert array_encoder_program == expected_array_encoder_program
  end

  test "print array fuzzer" do
    result =
      array_type()
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

  defp array_type,
    do: %ArrayType{
      name: "colors",
      path: ["#"],
      items: ["#", "items"]
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
      "#/items" => %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]
      }
    }
end
