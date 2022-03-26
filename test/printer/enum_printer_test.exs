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
        Decode.string |> Decode.andThen (parseColor >> Decode.fromResult)


    parseColor : String -> Result String Color
    parseColor color =
        case color of
            "none" ->
                Ok None

            "green" ->
                Ok Green

            "yellow" ->
                Ok Yellow

            "red" ->
                Ok Red

            _ ->
                Err <| "Unknown color type: " ++ color
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
        Decode.float |> Decode.andThen (parseTemperature >> Decode.fromResult)


    parseTemperature : Float -> Result String Temperature
    parseTemperature temperature =
        case temperature of
            -0.618 ->
                Ok FloatNeg0_618

            1.618 ->
                Ok Float1_618

            3.14 ->
                Ok Float3_14

            7.73 ->
                Ok Float7_73

            _ ->
                Err <| "Unknown temperature type: " ++ temperature
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
        color |> colorToString |> Encode.string


    colorToString : Color -> String
    colorToString color =
        case color of
            None ->
                "none"

            Green ->
                "green"

            Yellow ->
                "yellow"

            Red ->
                "red"
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
        temperature |> temperatureToFloat |> Encode.float


    temperatureToFloat : Temperature -> Float
    temperatureToFloat temperature =
        case temperature of
            FloatNeg0_618 ->
                -0.618

            Float1_618 ->
                1.618

            Float3_14 ->
                3.14

            Float7_73 ->
                7.73
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
        [ None, Green, Yellow, Red ]
            |> List.map Fuzz.constant
            |> Fuzz.oneOf


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
