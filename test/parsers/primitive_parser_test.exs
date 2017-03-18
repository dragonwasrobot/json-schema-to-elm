defmodule JS2ETest.Parsers.PrimitiveParser do
  use ExUnit.Case

  alias JS2E.Types.PrimitiveType
  alias JS2E.Parsers.PrimitiveParser

  test "parse primitive type" do

    type_dict =
      ~S"""
      {
        "type": "string"
      }
      """
      |> Poison.decode!()
      |> PrimitiveParser.parse(nil, ["#", "primitive"], "primitive")

    expected_primitive_type = %PrimitiveType{
      name: "primitive",
      path: ["#", "primitive"],
      type: "string"}

    assert type_dict == %{"#/primitive" => expected_primitive_type}
  end

end
