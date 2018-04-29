defmodule JS2ETest.Parser.AllOfParser do
  use ExUnit.Case
  doctest JS2E.Parser.AllOfParser, import: true

  require Logger
  alias JS2E.Types.{AllOfType, ObjectType, PrimitiveType, TypeReference}
  alias JS2E.Parser.AllOfParser

  defp all_of_type do
    ~S"""
    {
      "allOf": [
        {
          "type": "object",
          "properties": {
            "color": {
              "$ref": "#/definitions/color"
            },
            "description": {
              "type": "string"
            }
          },
          "required": [ "color" ]
        },
        {
          "$ref": "#/definitions/circle"
        }
      ]
    }
    """
  end

  defp parent_id, do: "http://www.example.com/schemas/fancyCircle.json"
  defp id, do: nil
  defp path, do: ["#", "definitions", "fancyCircle"]
  defp name, do: "fancyCircle"

  test "can parse all_of type" do
    parser_result =
      all_of_type()
      |> Poison.decode!()
      |> AllOfParser.parse(parent_id(), id(), path(), name())

    expected_all_of_type = %AllOfType{
      name: "fancyCircle",
      path: ["#", "definitions", "fancyCircle"],
      types: [
        path() ++ ["allOf", "0"],
        path() ++ ["allOf", "1"]
      ]
    }

    expected_object_type = %ObjectType{
      name: "0",
      path: path() ++ ["allOf", "0"],
      required: ["color"],
      properties: %{
        "color" => path() ++ ["allOf", "0", "properties", "color"],
        "description" => path() ++ ["allOf", "0", "properties", "description"]
      }
    }

    expected_color_type = %TypeReference{
      name: "color",
      path: ["#", "definitions", "color"]
    }

    expected_description_type = %PrimitiveType{
      name: "description",
      path: path() ++ ["allOf", "0", "properties", "description"],
      type: "string"
    }

    expected_circle_type = %TypeReference{
      name: "1",
      path: ["#", "definitions", "circle"]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/definitions/fancyCircle" => expected_all_of_type,
             "#/definitions/fancyCircle/allOf/0" => expected_object_type,
             "#/definitions/fancyCircle/allOf/0/properties/color" =>
               expected_color_type,
             "#/definitions/fancyCircle/allOf/0/properties/description" =>
               expected_description_type,
             "#/definitions/fancyCircle/allOf/1" => expected_circle_type
           }
  end
end
