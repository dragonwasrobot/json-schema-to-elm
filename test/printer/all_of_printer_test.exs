defmodule JS2ETest.Printer.AllOfPrinter do
  use ExUnit.Case

  require Logger

  alias JS2E.Types.{
    AllOfType,
    EnumType,
    ObjectType,
    PrimitiveType,
    TypeReference,
    SchemaDefinition
  }

  alias JS2E.Printer.AllOfPrinter

  def module_name, do: "Data"

  def type_dict do
    %{
      "#/schema/allOf/0" => %ObjectType{
        name: "0",
        path: ["#", "schema", "allOf", "0"],
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "schema", "allOf", "0", "properties", "color"],
          "title" => ["#", "schema", "allOf", "0", "properties", "title"],
          "radius" => ["#", "schema", "allOf", "0", "properties", "radius"]
        }
      },
      "#/schema/allOf/0/properties/color" => %TypeReference{
        name: "color",
        path: ["#", "definitions", "color"]
      },
      "#/schema/allOf/0/properties/radius" => %PrimitiveType{
        name: "radius",
        path: ["#", "schema", "allOf", "0", "properties", "radius"],
        type: "number"
      },
      "#/schema/allOf/0/properties/title" => %PrimitiveType{
        name: "title",
        path: ["#", "schema", "allOf", "0", "properties", "title"],
        type: "string"
      },
      "#/schema/allOf/1" => %ObjectType{
        name: "1",
        path: ["#", "schema", "allOf", "1"],
        required: ["type"],
        properties: %{
          "type" => ["#", "schema", "allOf", "1", "properties", "type"]
        }
      },
      "#/schema/allOf/1/properties/type" => %PrimitiveType{
        name: "type",
        path: ["#", "schema", "allOf", "1", "properties", "type"],
        type: "string"
      },
      "#/definitions/color" => %EnumType{
        name: "color",
        path: ["#", "definitions", "color"],
        type: "string",
        values: ["none", "green", "yellow", "red"]
      }
    }
  end

  def schema_def do
    %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      title: "Test",
      types: type_dict
    }
  end

  def all_of_type do
    %AllOfType{
      name: "schema",
      path: ["#", "schema"],
      types: [
        ["#", "schema", "allOf", "0"],
        ["#", "schema", "allOf", "1"]
      ]
    }
  end

  test "print 'all of' type value" do
    module_name = "Data"

    result =
      all_of_type
      |> AllOfPrinter.print_type(schema_def, %{}, module_name)

    all_of_type_program = result.printed_schema

    expected_all_of_type_program = """
    type alias Schema =
        { zero : Zero
        , one : One
        }
    """

    assert all_of_type_program == expected_all_of_type_program
  end

  test "print 'all of' decoder" do
    result =
      all_of_type
      |> AllOfPrinter.print_decoder(schema_def, %{}, module_name)

    expected_all_of_decoder_program = """
    schemaDecoder : Decoder Schema
    schemaDecoder =
        decode Schema
            |> custom zeroDecoder
            |> custom oneDecoder
    """

    all_of_decoder_program = result.printed_schema

    assert all_of_decoder_program == expected_all_of_decoder_program
  end

  test "print 'all of' encoder" do
    result =
      all_of_type
      |> AllOfPrinter.print_encoder(schema_def, %{}, module_name)

    expected_all_of_encoder_program = """
    encodeSchema : Schema -> Value
    encodeSchema schema =
        let
            color =
                encodeColor schema.zero.color

            radius =
                Encode.float schema.zero.radius

            title =
                Encode.string schema.zero.title

            type =
                Encode.string schema.one.type
        in
            object <|
                color ++ radius ++ title ++ type
    """

    all_of_encoder_program = result.printed_schema

    assert all_of_encoder_program == expected_all_of_encoder_program
  end
end
