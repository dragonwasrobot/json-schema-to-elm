defmodule JS2ETest.Parsers.OneOfParser do
  use ExUnit.Case
  doctest JS2E.Parsers.OneOfParser, import: true

  alias JS2E.Types.{OneOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.OneOfParser

  test "parse primitive one_of type" do

    parser_result =
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
      |> OneOfParser.parse(nil, nil, ["#", "schema"], "schema")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "schema", "oneOf", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "schema", "oneOf", "0", "properties", "color"],
        "title" => ["#", "schema", "oneOf", "0", "properties", "title"],
        "radius" => ["#", "schema", "oneOf", "0","properties",  "radius"]}
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "schema", "oneOf", "1"],
      type: "string"}

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "color"]}

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "schema", "oneOf", "0", "properties", "radius"],
      type: "number"}

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "schema", "oneOf", "0", "properties", "title"],
      type: "string"}

    expected_one_of_type = %OneOfType{
      name: "schema",
      path: ["#", "schema"],
      types: [
        ["#", "schema", "oneOf", "0"],
        ["#", "schema", "oneOf", "1"]
      ]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []
    assert parser_result.type_dict == %{
      "#/schema" => expected_one_of_type,
      "#/schema/oneOf/0" => expected_object_type,
      "#/schema/oneOf/1" => expected_primitive_type,
      "#/schema/oneOf/0/properties/color" => expected_color_type,
      "#/schema/oneOf/0/properties/radius" => expected_radius_type,
      "#/schema/oneOf/0/properties/title" => expected_title_type
    }
  end

end
