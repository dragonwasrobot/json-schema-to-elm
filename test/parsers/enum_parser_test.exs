defmodule JS2ETest.Parsers.EnumParser do
  use ExUnit.Case

  alias JS2E.Types.EnumType
  alias JS2E.Parsers.EnumParser

  test "parse enum type with integer values" do

    type_dict =
      ~S"""
      {
        "type": "integer",
        "enum": [1, 2, 3]
      }
      """
      |> Poison.decode!()
      |> EnumParser.parse(nil, nil, ["#", "favoriteNumber"], "favoriteNumber")

    expected_enum_type = %EnumType{
      name: "favoriteNumber",
      path: ["#", "favoriteNumber"],
      type: "integer",
      values: [1, 2, 3]}

    assert type_dict == %{"#/favoriteNumber" => expected_enum_type}
  end

  test "parse enum type with string values" do

    type_dict =
      ~S"""
      {
        "type": "string",
        "enum": ["none", "green", "orange", "blue", "yellow", "red"]
      }
      """
      |> Poison.decode!()
      |> EnumParser.parse(nil, nil, ["#", "color"], "color")

    expected_enum_type = %EnumType{
      name: "color",
      path: ["#", "color"],
      type: "string",
      values: ["none", "green", "orange", "blue", "yellow", "red"]}

    assert type_dict == %{"#/color" => expected_enum_type}
  end

end
