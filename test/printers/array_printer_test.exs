defmodule JS2ETest.Printers.ArrayPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{ArrayType, EnumType, SchemaDefinition}
  alias JS2E.Printers.ArrayPrinter

  test "print array type" do
    module_name = "Domain"

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: %{}
    }

    result =
      %ArrayType{
        name: "colors",
        path: ["#", "items"],
        items: ["#", "definitions", "color"]
      }
      |> ArrayPrinter.print_type(schema_def, %{}, module_name)

    expected_array_type_program = ""
    array_type_program = result.printed_schema

    assert array_type_program == expected_array_type_program
  end

  test "print array decoder" do
    module_name = "Domain"

    type_dict = %{
      "#/items" => %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]
      }
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }

    result =
      %ArrayType{
        name: "colors",
        path: ["#"],
        items: ["#", "items"]
      }
      |> ArrayPrinter.print_decoder(schema_def, %{}, module_name)

    expected_array_decoder_program = """
    colorsDecoder : Decoder (List Color)
    colorsDecoder =
        Decode.list colorDecoder
    """

    array_decoder_program = result.printed_schema

    assert array_decoder_program == expected_array_decoder_program
  end

  test "print array encoder" do
    module_name = "Domain"

    type_dict = %{
      "#/items" => %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]
      }
    }

    schema_def = %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }

    result =
      %ArrayType{
        name: "colors",
        path: ["#"],
        items: ["#", "items"]
      }
      |> ArrayPrinter.print_encoder(schema_def, %{}, module_name)

    expected_array_encoder_program = """
    encodeColors : List Color -> Value
    encodeColors colors =
        Encode.list <| List.map encodeColor <| colors
    """

    array_encoder_program = result.printed_schema

    assert array_encoder_program == expected_array_encoder_program
  end
end
