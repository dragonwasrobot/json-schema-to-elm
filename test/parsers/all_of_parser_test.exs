defmodule JS2ETest.Parsers.AllOfParser do
  use ExUnit.Case
  doctest JS2E.Parsers.AllOfParser, import: true

  require Logger
  alias JS2E.Types.{AllOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parsers.{AllOfParser, ParserError, ParserWarning}

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
      |> AllOfParser.parse(nil, nil, ["#", "allOfExample"], "allOfExample")

    expected_object_type = %ObjectType{
      name: "0",
      path: ["#", "allOfExample", "0"],
      required: ["color", "radius"],
      properties: %{
        "color" => ["#", "allOfExample", "0", "color"],
        "title" => ["#", "allOfExample", "0", "title"],
        "radius" => ["#", "allOfExample", "0", "radius"]}
    }

    expected_primitive_type = %PrimitiveType{
      name: "1",
      path: ["#", "allOfExample", "1"],
      type: "string"}

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "color"]}

    expected_radius_type = %PrimitiveType{
      name: "radius",
      path: ["#", "allOfExample", "0", "radius"],
      type: "number"}

    expected_title_type = %PrimitiveType{
      name: "title",
      path: ["#", "allOfExample", "0", "title"],
      type: "string"}

    expected_all_of_type = %AllOfType{
      name: "allOfExample",
      path: ["#", "allOfExample"],
      types: [
        ["#", "allOfExample", "0"],
        ["#", "allOfExample", "1"]
      ]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []
    assert parser_result.type_dict == %{
      "#/allOfExample" => expected_all_of_type,
      "#/allOfExample/0" => expected_object_type,
      "#/allOfExample/1" => expected_primitive_type,
      "#/allOfExample/0/color" => expected_color_type,
      "#/allOfExample/0/radius" => expected_radius_type,
      "#/allOfExample/0/title" => expected_title_type
    }
  end

  test "reports type error if allOf has wrong type" do

    parser_result =
      ~S"""
      {
        "allOf": {
          "type": "string"
        }
      }
      """
      |> Poison.decode!()
      |> AllOfParser.parse(nil, nil, ["#", "allOfExample"], "allOfExample")

    [error] = parser_result.errors
    Logger.debug "Error: #{inspect error}"

    assert error.error_type == :type_mismatch
    assert error.identifier == ["#", "allOfExample"]
  end

end
