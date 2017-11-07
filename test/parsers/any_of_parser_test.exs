defmodule JS2ETest.Parsers.AnyOfParser do
  use ExUnit.Case
  doctest JS2E.Parsers.AnyOfParser, import: true

  alias JS2E.Types.{AnyOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.AnyOfParser

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
      |> AnyOfParser.parse(parent, nil, ["#", "anyOfExample"], "anyOfExample")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "anyOfExample", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "anyOfExample", "0", "color"],
        "title" => ["#", "anyOfExample", "0", "title"],
        "radius" => ["#", "anyOfExample", "0", "radius"]}
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "anyOfExample", "1"],
      type: "string"}

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "color"]}

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "anyOfExample", "0", "radius"],
      type: "number"}

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "anyOfExample", "0", "title"],
      type: "string"}

    expected_any_of_type = %AnyOfType{
      name: "anyOfExample",
      path: ["#", "anyOfExample"],
      types: [
        ["#", "anyOfExample", "0"],
        ["#", "anyOfExample", "1"]
      ]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []
    assert parser_result.type_dict == %{
      "#/anyOfExample" => expected_any_of_type,
      "#/anyOfExample/0" => expected_object_type,
      "#/anyOfExample/1" => expected_primitive_type,
      "#/anyOfExample/0/color" => expected_color_type,
      "#/anyOfExample/0/radius" => expected_radius_type,
      "#/anyOfExample/0/title" => expected_title_type
    }
  end

end
