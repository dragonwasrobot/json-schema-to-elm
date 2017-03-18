defmodule JS2ETest.Parsers.DefinitionsParser do
  use ExUnit.Case

  alias JS2E.{Types, Parser}
  alias Types.{ArrayType, TypeReference, PrimitiveType, SchemaDefinition}

  test "parse definitions" do

    type_dict =
      ~S"""
      {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title": "",
        "id": "http://example.com/root.json",
        "type": "array",
        "items": { "$ref": "#/definitions/positiveInteger" },
        "definitions": {
          "positiveInteger": {
            "type": "integer",
            "minimum": 0,
            "exclusiveMinimum": true
          }
        }
      }
      """
      |> Poison.decode!()
      |> Parser.parse_schema()

    expected_root_type_reference = %ArrayType{
      name: "",
      path: ["#"],
      items: ["#", "items"]}

    expected_type_reference = %TypeReference{
      name: "items",
      path: ["#", "definitions", "positiveInteger"]}

    expected_primitive_type = %PrimitiveType{
      name: "positiveInteger",
      path: ["#", "definitions", "positiveInteger"],
      type: "integer"}

    assert type_dict == %{
      "http://example.com/root.json" =>
      %SchemaDefinition{
        title: "",
        id: "http://example.com/root.json",
        types: %{
          "#" => expected_root_type_reference,
          "http://example.com/root.json" => expected_root_type_reference,
          "#/items" => expected_type_reference,
          "#/definitions/positiveInteger" => expected_primitive_type}}
    }
  end

end
