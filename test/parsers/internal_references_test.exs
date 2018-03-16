defmodule JS2ETest.Parsers.InternalReferences do
  use ExUnit.Case

  alias JS2E.Types
  alias Types.{PrimitiveType, TypeReference, SchemaDefinition}
  alias JS2E.Parsers.RootParser

  test "parse internal references" do
    schema_result =
      ~S"""
      {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "description": "Demonstrates the different types of internal references",
        "title": "Internal references",
        "id": "http://example.com/root.json",
        "type": "object",
        "$ref": "#/definitions/C",
        "definitions": {
          "A": {
            "id": "#foo",
            "type": "string"
          },
          "B": {
            "id": "other.json",
            "definitions": {
              "X": {
                "id": "#bar",
                "type": "boolean"
              },
              "Y": {
                "id": "t/inner.json",
                "type": "number"
              }
            }
          },
          "C": {
            "id": "urn:uuid:ee564b8a-7a87-4125-8c96-e9f123d6766f",
            "type": "integer"
          }
        }
      }
      """
      |> Poison.decode!()
      |> RootParser.parse_schema("examples/example.json")

    expected_root_type_reference = %TypeReference{name: "#", path: ["#", "definitions", "C"]}

    expected_type_a = %PrimitiveType{name: "A", path: ["#", "definitions", "A"], type: "string"}

    expected_type_x = %PrimitiveType{
      name: "X",
      path: ["#", "definitions", "B", "definitions", "X"],
      type: "boolean"
    }

    expected_type_y = %PrimitiveType{
      name: "Y",
      path: ["#", "definitions", "B", "definitions", "Y"],
      type: "number"
    }

    expected_type_c = %PrimitiveType{name: "C", path: ["#", "definitions", "C"], type: "integer"}

    assert schema_result.errors == []
    assert schema_result.warnings == []

    assert schema_result.schema_dict == %{
             "http://example.com/root.json" => %SchemaDefinition{
               file_path: "examples/example.json",
               description: "Demonstrates the different types of internal references",
               title: "Internal references",
               id: URI.parse("http://example.com/root.json"),
               types: %{
                 "#" => expected_root_type_reference,
                 "http://example.com/root.json#" => expected_root_type_reference,
                 "#/definitions/A" => expected_type_a,
                 "http://example.com/root.json#foo" => expected_type_a,
                 "#/definitions/B/definitions/X" => expected_type_x,
                 "http://example.com/other.json#bar" => expected_type_x,
                 "#/definitions/B/definitions/Y" => expected_type_y,
                 "http://example.com/t/inner.json" => expected_type_y,
                 "#/definitions/C" => expected_type_c,
                 "urn:uuid:ee564b8a-7a87-4125-8c96-e9f123d6766f" => expected_type_c
               }
             }
           }
  end
end
