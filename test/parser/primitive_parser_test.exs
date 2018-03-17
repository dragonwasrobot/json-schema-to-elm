defmodule JS2ETest.Parser.PrimitiveParser do
  use ExUnit.Case
  doctest JS2E.Parser.PrimitiveParser, import: true

  alias JS2E.Types.PrimitiveType
  alias JS2E.Parser.PrimitiveParser

  test "parse primitive type" do
    parser_result =
      ~S"""
      {
        "type": "string"
      }
      """
      |> Poison.decode!()
      |> PrimitiveParser.parse(nil, nil, ["#", "primitive"], "primitive")

    expected_primitive_type = %PrimitiveType{
      name: "primitive",
      path: ["#", "primitive"],
      type: "string"
    }

    assert parser_result.errors == []
    assert parser_result.warnings == []

    assert parser_result.type_dict == %{
             "#/primitive" => expected_primitive_type
           }
  end
end
