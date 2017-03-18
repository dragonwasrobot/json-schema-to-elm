defmodule JS2ETest.Parsers.OneOfParser do
  use ExUnit.Case

  alias JS2E.Types.{OneOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.OneOfParser

  test "parse primitive one_of type" do

    type_dict =
      ~S"""
      {
        "oneOf": [
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
      |> OneOfParser.parse(nil, nil, ["#", "oneOfExample"], "oneOfExample")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "oneOfExample", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "oneOfExample", "0", "color"],
        "title" => ["#", "oneOfExample", "0", "title"],
        "radius" => ["#", "oneOfExample", "0", "radius"]}
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "oneOfExample", "1"],
      type: "string"}

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "color"]}

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "oneOfExample", "0", "radius"],
      type: "number"}

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "oneOfExample", "0", "title"],
      type: "string"}

    expected_one_of_type = %OneOfType{
      name: "oneOfExample",
      path: ["#", "oneOfExample"],
      types: [
        ["#", "oneOfExample", "0"],
        ["#", "oneOfExample", "1"]
      ]
    }

    assert type_dict == %{
      "#/oneOfExample" => expected_one_of_type,
      "#/oneOfExample/0" => expected_object_type,
      "#/oneOfExample/1" => expected_primitive_type,
      "#/oneOfExample/0/color" => expected_color_type,
      "#/oneOfExample/0/radius" => expected_radius_type,
      "#/oneOfExample/0/title" => expected_title_type
    }
  end

end
