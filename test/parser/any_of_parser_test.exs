defmodule JS2ETest.Parser.AnyOfParser do
  use ExUnit.Case
  doctest JS2E.Parser.AnyOfParser, import: true

  alias JS2E.Types.{AnyOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parser.AnyOfParser

  test "parse primitive any_of type" do
    parent = "http://www.example.com/schema.json"

    parser_result =
      ~S"""
      {
        "anyOf": [
          {
            "type": "object",
            "properties": {
              "color": {
                "$ref": "#/definitions/color"
              },
              "title": {
                "type": "string"
              },
              "radius": {
                "type": "number"
              }
            },
            "required": [ "color", "radius" ]
          },
          {
            "type": "string"
          }
        ]
      }
      """
      |> Poison.decode!()
      |> AnyOfParser.parse(parent, nil, ["#", "schema"], "schema")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "schema", "anyOf", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "schema", "anyOf", "0", "properties", "color"],
        "title" => ["#", "schema", "anyOf", "0", "properties", "title"],
        "radius" => ["#", "schema", "anyOf", "0", "properties", "radius"]
      }
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "schema", "anyOf", "1"],
      type: "string"
    }

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "definitions", "color"]
    }

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "schema", "anyOf", "0", "properties", "radius"],
      type: "number"
    }

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "schema", "anyOf", "0", "properties", "title"],
      type: "string"
    }

    expected_any_of_type = %AnyOfType{
      name: "schema",
      path: ["#", "schema"],
      types: [
        ["#", "schema", "anyOf", "0"],
        ["#", "schema", "anyOf", "1"]
      ]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/schema" => expected_any_of_type,
             "#/schema/anyOf/0" => expected_object_type,
             "#/schema/anyOf/1" => expected_primitive_type,
             "#/schema/anyOf/0/properties/color" => expected_color_type,
             "#/schema/anyOf/0/properties/radius" => expected_radius_type,
             "#/schema/anyOf/0/properties/title" => expected_title_type
           }
  end
end
