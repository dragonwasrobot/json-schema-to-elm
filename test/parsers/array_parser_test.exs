defmodule JS2ETest.Parsers.ArrayParser do
  use ExUnit.Case
  doctest JS2E.Parsers.ArrayParser, import: true

  alias JS2E.Types.{ArrayType, TypeReference}
  alias JS2E.Parsers.ArrayParser

  test "parse array type" do

    type_dict =
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
      items: ["#", "rectangles", "items"]}

    expected_type_reference = %TypeReference{
      name: "items",
      path: ["#", "definitions", "rectangle"]}

    assert type_dict == %{
      "#/rectangles" => expected_array_type,
      "#/rectangles/items" => expected_type_reference}
  end

end
