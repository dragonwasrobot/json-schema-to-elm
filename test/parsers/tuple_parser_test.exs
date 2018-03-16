defmodule JS2ETest.Parsers.TupleParser do
  use ExUnit.Case
  doctest JS2E.Parsers.TupleParser, import: true

  alias JS2E.Types.{TupleType, TypeReference}
  alias JS2E.Parsers.TupleParser

  test "parse tuple type" do
    parser_result =
      ~S"""
      {
        "type": "array",
        "items": [
          { "$ref": "#/definitions/rectangle" },
          { "$ref": "#/definitions/circle" }
        ]
      }
      """
      |> Poison.decode!()
      |> TupleParser.parse(nil, nil, ["#", "shapePair"], "shapePair")

    expected_tuple_type = %TupleType{
      name: "shapePair",
      path: ["#", "shapePair"],
      items: [["#", "shapePair", "items", "0"], ["#", "shapePair", "items", "1"]]
    }

    expected_rectangle_type_reference = %TypeReference{
      name: "0",
      path: ["#", "definitions", "rectangle"]
    }

    expected_circle_type_reference = %TypeReference{
      name: "1",
      path: ["#", "definitions", "circle"]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/shapePair" => expected_tuple_type,
             "#/shapePair/items/0" => expected_rectangle_type_reference,
             "#/shapePair/items/1" => expected_circle_type_reference
           }
  end
end
