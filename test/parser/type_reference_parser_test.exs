defmodule JS2ETest.Parser.TypeReferenceParser do
  use ExUnit.Case
  doctest JS2E.Parser.TypeReferenceParser, import: true

  alias JS2E.{Parser, Types}
  alias Parser.TypeReferenceParser
  alias Types.TypeReference

  test "parse type reference" do
    parser_result =
      ~S"""
      {
        "$ref": "#/definitions/targetTypeId"
      }
      """
      |> Poison.decode!()
      |> TypeReferenceParser.parse(nil, nil, ["#", "typeRef"], "typeRef")

    expected_type_reference = %TypeReference{
      name: "typeRef",
      path: ["#", "definitions", "targetTypeId"]
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/typeRef" => expected_type_reference
           }
  end
end
