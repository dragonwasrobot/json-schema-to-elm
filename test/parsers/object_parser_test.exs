defmodule JS2ETest.Parsers.ObjectParser do
  use ExUnit.Case
  doctest JS2E.Parsers.ObjectParser

  alias JS2E.Types.{ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.ObjectParser

  test "parse object type" do

    type_dict =
      ~S"""
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
      }
      """
      |> Poison.decode!()
      |> ObjectParser.parse(nil, nil, ["#", "circle"], "circle")

    expected_object_type = %ObjectType{
      name: "circle",
      path: ["#", "circle"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "circle", "color"],
        "title" => ["#", "circle", "title"],
        "radius" => ["#", "circle", "radius"]}
    }

    expected_color_type_reference = %TypeReference{
      name: "color",
      path: ["#", "color"]
    }

    expected_title_primitive_type = %PrimitiveType{
      name: "title",
      path: ["#", "circle", "title"],
      type: "string"
    }

    expected_radius_primitive_type = %PrimitiveType{
      name: "radius",
      path: ["#", "circle", "radius"],
      type: "number"
    }

    assert type_dict == %{
      "#/circle" => expected_object_type,
      "#/circle/color" => expected_color_type_reference,
      "#/circle/title" => expected_title_primitive_type,
      "#/circle/radius" => expected_radius_primitive_type}
  end

end
