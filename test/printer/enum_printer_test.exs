defmodule JS2ETest.Printer.EnumPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.EnumPrinter
  alias Types.{EnumType, SchemaDefinition}

  test "print enum type with string values" do
    result =
      enum_type_with_strings()
      |> EnumPrinter.print_type(schema_def(), %{}, module_name())

    expected_enum_type_program = """
    type Color
        = None
        | Green
        | Yellow
        | Red
    """

    enum_type_program = result.printed_schema

    assert enum_type_program == expected_enum_type_program
  end

  test "print enum type with number values" do
    result =
      enum_type_with_numbers()
      |> EnumPrinter.print_type(schema_def(), %{}, module_name())

    expected_enum_type_program = """
    type Temperature
        = FloatNeg0_618
        | Float1_618
        | Float3_14
        | Float7_73
    """

    enum_type_program = result.printed_schema

    assert enum_type_program == expected_enum_type_program
  end

  test "print enum decoder with string values" do
    result =
      enum_type_with_strings()
      |> EnumPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_enum_decoder_program = """
    colorDecoder : Decoder Color
    colorDecoder =
        Decode.string
            |> andThen
                (\\color ->
                    case color of
                        "none" ->
                            succeed None

                        "green" ->
                            succeed Green

                        "yellow" ->
                            succeed Yellow

                        "red" ->
                            succeed Red

                        _ ->
                            fail <| "Unknown color type: " ++ color
                )
    """

    enum_decoder_program = result.printed_schema

    assert enum_decoder_program == expected_enum_decoder_program
  end

  test "print enum decoder with number values" do
    result =
      enum_type_with_numbers()
      |> EnumPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_enum_decoder_program = """
    temperatureDecoder : Decoder Temperature
    temperatureDecoder =
        Decode.string
            |> andThen
                (\\temperature ->
                    case temperature of
                        -0.618 ->
                            succeed FloatNeg0_618

                        1.618 ->
                            succeed Float1_618

                        3.14 ->
                            succeed Float3_14

                        7.73 ->
                            succeed Float7_73

                        _ ->
                            fail <| "Unknown temperature type: " ++ temperature
                )
    """

    enum_decoder_program = result.printed_schema

    assert enum_decoder_program == expected_enum_decoder_program
  end

  test "print enum encoder with string values" do
    result =
      enum_type_with_strings()
      |> EnumPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_enum_encoder_program = """
    encodeColor : Color -> Value
    encodeColor color =
        case color of
            None ->
                Encode.string "none"

            Green ->
                Encode.string "green"

            Yellow ->
                Encode.string "yellow"

            Red ->
                Encode.string "red"
    """

    enum_encoder_program = result.printed_schema

    assert enum_encoder_program == expected_enum_encoder_program
  end

  test "print enum encoder with number values" do
    result =
      enum_type_with_numbers()
      |> EnumPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_enum_encoder_program = """
    encodeTemperature : Temperature -> Value
    encodeTemperature temperature =
        case temperature of
            FloatNeg0_618 ->
                Encode.float -0.618

            Float1_618 ->
                Encode.float 1.618

            Float3_14 ->
                Encode.float 3.14

            Float7_73 ->
                Encode.float 7.73
    """

    enum_encoder_program = result.printed_schema

    assert enum_encoder_program == expected_enum_encoder_program
  end

  test "print enum fuzzer with string values" do
    result =
      enum_type_with_strings()
      |> EnumPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_enum_fuzzer_program = """
    colorFuzzer : Fuzzer Color
    colorFuzzer =
        Fuzz.oneOf
            [ Fuzz.constant None
            , Fuzz.constant Green
            , Fuzz.constant Yellow
            , Fuzz.constant Red
            ]


    encodeDecodeColorTest : Test
    encodeDecodeColorTest =
        fuzz colorFuzzer "can encode and decode Color object" <|
            \\color ->
                color
                    |> encodeColor
                    |> Decode.decodeValue colorDecoder
                    |> Expect.equal (Ok color)
    """

    enum_fuzzer_program = result.printed_schema

    assert enum_fuzzer_program == expected_enum_fuzzer_program
  end

  defp module_name, do: "Domain"

  defp enum_type_with_strings,
    do: %EnumType{
      name: "color",
      path: ["#", "definitions", "color"],
      type: "string",
      values: ["none", "green", "yellow", "red"]
    }

  defp enum_type_with_numbers,
    do: %EnumType{
      name: "temperature",
      path: ["#", "definitions", "temperature"],
      type: "number",
      values: [-0.618, 1.618, 3.14, 7.73]
    }

  defp schema_def,
    do: %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      file_path: "test.json",
      title: "Test",
      types: %{}
    }
end
