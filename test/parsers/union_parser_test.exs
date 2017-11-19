defmodule JS2ETest.Parsers.UnionParser do
  use ExUnit.Case
  doctest JS2E.Parsers.UnionParser, import: true

  alias JS2E.Types.UnionType
  alias JS2E.Parsers.UnionParser

  test "parse primitive union type" do

    parser_result =
      ~S"""
      {
        "type": ["number", "integer", "null"]
      }
      """
      |> Poison.decode!()
      |> UnionParser.parse(nil, nil, ["#", "union"], "union")

    expected_union_type = %UnionType{
      name: "union",
      path: ["#", "union"],
      types: ["number", "integer", "null"]}

    assert parser_result.errors == []
    assert parser_result.warnings == []
    assert parser_result.type_dict == %{
      "#/union" => expected_union_type
    }
  end

end
