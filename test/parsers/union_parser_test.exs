defmodule JS2ETest.Parsers.UnionParser do
  use ExUnit.Case

  alias JS2E.Types.UnionType
  alias JS2E.Parsers.UnionParser

  test "parse primitive union type" do

    type_dict =
      ~S"""
      {
        "type": ["number", "integer", "null"]
      }
      """
      |> Poison.decode!()
      |> UnionParser.parse(nil, ["#", "union"], "union")

    expected_union_type = %UnionType{
      name: "union",
      path: ["#", "union"],
      types: ["number", "integer", "null"]}

    assert type_dict == %{"#/union" => expected_union_type}
  end

end
