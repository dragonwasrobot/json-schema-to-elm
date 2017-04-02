defmodule JS2ETest.Printers.ArrayPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{ArrayType, EnumType}
  alias JS2E.Printers.ArrayPrinter

  test "print array type" do

    type_dict = %{}

    array_type_program =
      %ArrayType{
        name: "colors",
        path: ["#", "items"],
        items: ["#", "definitions", "color"]
      }
      |> ArrayPrinter.print_type(type_dict, %{})

    expected_array_type_program = ""

    assert array_type_program == expected_array_type_program
  end

  test "print array decoder" do

    type_dict = %{
      "#/items" =>
      %EnumType{name: "color",
                path: ["#", "definitions", "color"],
                type: "string",
                values: ["none", "green", "yellow", "red"]}
    }

    array_decoder_program =
      %ArrayType{
        name: "colors",
        path: ["#"],
        items: ["#", "items"]
      }
      |> ArrayPrinter.print_decoder(type_dict, %{})

    expected_array_decoder_program =
    """
    colorsDecoder : Decoder (List Color)
    colorsDecoder =
        Decode.list colorDecoder
    """

    assert array_decoder_program == expected_array_decoder_program
  end

  test "print array encoder" do

    type_dict = %{
      "#/items" =>
      %EnumType{name: "color",
                path: ["#", "definitions", "color"],
                type: "string",
                values: ["none", "green", "yellow", "red"]}
    }

    array_encoder_program =
      %ArrayType{
        name: "colors",
        path: ["#"],
        items: ["#", "items"]
      }
      |> ArrayPrinter.print_encoder(type_dict, %{})

    expected_array_encoder_program =
    """
    encodeColors : List Color -> Value
    encodeColors colors =
        Encode.list <| List.map encodeColor <| colors
    """

    assert array_encoder_program == expected_array_encoder_program
  end

end
