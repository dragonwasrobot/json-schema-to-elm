defmodule JS2ETest.Parsers.AllOfParser do
  use ExUnit.Case
  doctest JS2E.Parsers.AllOfParser, import: true

  require Logger
  alias JS2E.Types.{AllOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.AllOfParser

  test "parse primitive all_of type" do
    parser_result =
      ~S"""
      {
        "allOf": [
          {
            "type": "object",
            "properties": {
              "color": {
                "$ref": "#/color"
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
      |> AllOfParser.parse(nil, nil, ["#", "schema"], "schema")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "schema", "allOf", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "schema", "allOf", "0", "properties", "color"],
        "title" => ["#", "schema", "allOf", "0", "properties", "title"],
        "radius" => ["#", "schema", "allOf", "0", "properties", "radius"]
      }
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "schema", "allOf", "1"],
      type: "string"
    }

    expected_color_type = %TypeReference{name: "color", path: ["#", "color"]}

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "schema", "allOf", "0", "properties", "radius"],
      type: "number"
    }

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "schema", "allOf", "0", "properties", "title"],
      type: "string"
    }

    expected_all_of_type = %AllOfType{
      name: "schema",
      path: ["#", "schema"],
      types: [
        ["#", "schema", "allOf", "0"],
        ["#", "schema", "allOf", "1"]
      ]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/schema" => expected_all_of_type,
             "#/schema/allOf/0" => expected_object_type,
             "#/schema/allOf/1" => expected_primitive_type,
             "#/schema/allOf/0/properties/color" => expected_color_type,
             "#/schema/allOf/0/properties/radius" => expected_radius_type,
             "#/schema/allOf/0/properties/title" => expected_title_type
           }
  end
end
