defmodule JS2ETest.Parsers.ObjectParser do
  use ExUnit.Case
  doctest JS2E.Parsers.ObjectParser, import: true

  alias JS2E.Types.{ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.ObjectParser

  test "parse object type" do
    parser_result =
      ~S"""
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
        "required": ["color", "radius"]
      }
      """
      |> Poison.decode!()
      |> ObjectParser.parse(nil, nil, ["#", "circle"], "circle")

    expected_object_type = %ObjectType{
      name: "circle",
      path: ["#", "circle"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "circle", "properties", "color"],
        "title" => ["#", "circle", "properties", "title"],
        "radius" => ["#", "circle", "properties", "radius"]
      }
    }

    expected_color_type_reference = %TypeReference{
      name: "color",
      path: ["#", "definitions", "color"]
    }

    expected_title_primitive_type = %PrimitiveType{
      name: "title",
      path: ["#", "circle", "properties", "title"],
      type: "string"
    }

    expected_radius_primitive_type = %PrimitiveType{
      name: "radius",
      path: ["#", "circle", "properties", "radius"],
      type: "number"
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/circle" => expected_object_type,
             "#/circle/properties/color" => expected_color_type_reference,
             "#/circle/properties/title" => expected_title_primitive_type,
             "#/circle/properties/radius" => expected_radius_primitive_type
           }
  end
end
