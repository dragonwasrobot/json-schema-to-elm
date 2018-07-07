defmodule JS2ETest.Parser.ArrayParser do
  use ExUnit.Case
  doctest JS2E.Parser.ArrayParser, import: true

  alias JS2E.{Parser, Types}
  alias Parser.ArrayParser
  alias Types.{ArrayType, TypeReference}

  test "parse array type" do
    parser_result =
      ~S"""
      {
        "type": "array",
        "items": {
          "$ref": "#/definitions/rectangle"
        }
      }
      """
      |> Poison.decode!()
      |> ArrayParser.parse(nil, nil, ["#", "rectangles"], "rectangles")

    expected_array_type = %ArrayType{
      name: "rectangles",
      path: ["#", "rectangles"],
      items: ["#", "rectangles", "items"]
    }

    expected_type_reference = %TypeReference{
      name: "items",
      path: ["#", "definitions", "rectangle"]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/rectangles" => expected_array_type,
             "#/rectangles/items" => expected_type_reference
           }
  end
end
