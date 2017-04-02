defmodule JS2ETest.Printers.EnumPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.EnumType
  alias JS2E.Printers.EnumPrinter

  test "print enum type with string values" do

    type_dict = %{}

    enum_type_program =
      %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]}
        |> EnumPrinter.print_type(type_dict, %{})

    expected_enum_type_program =
    """
    type Color
        = None
        | Green
        | Yellow
        | Red
    """

    assert enum_type_program == expected_enum_type_program
  end

  test "print enum type with number values" do

    type_dict = %{}

    enum_type_program =
      %EnumType{
        name: "temperature",
        path: ["#", "definitions", "temperature"],
        type: "number",
        values: [-0.618, 1.618, 3.14, 7.73]}
        |> EnumPrinter.print_type(type_dict, %{})

    expected_enum_type_program =
    """
    type Temperature
        = FloatNeg0_618
        | Float1_618
        | Float3_14
        | Float7_73
    """

    assert enum_type_program == expected_enum_type_program
  end

  test "print enum decoder with string values" do

    type_dict = %{}

    enum_decoder_program =
      %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]}
        |> EnumPrinter.print_decoder(type_dict, %{})

    expected_enum_decoder_program =
    """
    colorDecoder : String -> Decoder Color
    colorDecoder color =
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
    """

    assert enum_decoder_program == expected_enum_decoder_program
  end

  test "print enum decoder with number values" do

    type_dict = %{}

    enum_decoder_program =
      %EnumType{
        name: "temperature",
        path: ["#", "definitions", "temperature"],
        type: "number",
        values: [-0.618, 1.618, 3.14, 7.73]}
        |> EnumPrinter.print_decoder(type_dict, %{})

    expected_enum_decoder_program =
    """
    temperatureDecoder : Float -> Decoder Temperature
    temperatureDecoder temperature =
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
    """

    assert enum_decoder_program == expected_enum_decoder_program
  end

  test "print enum encoder with string values" do

    type_dict = %{}

    enum_encoder_program =
      %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]}
        |> EnumPrinter.print_encoder(type_dict, %{})

    expected_enum_encoder_program =
    """
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

    assert enum_encoder_program == expected_enum_encoder_program
  end

  test "print enum encoder with number values" do

    type_dict = %{}

    enum_encoder_program =
      %EnumType{
        name: "temperature",
        path: ["#", "definitions", "temperature"],
        type: "number",
        values: [-0.618, 1.618, 3.14, 7.73]}
        |> EnumPrinter.print_encoder(type_dict, %{})

    expected_enum_encoder_program =
    """
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

    assert enum_encoder_program == expected_enum_encoder_program
  end

end
