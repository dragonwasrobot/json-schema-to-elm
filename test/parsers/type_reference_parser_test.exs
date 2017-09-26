defmodule JS2ETest.Parsers.TypeReferenceParser do
  use ExUnit.Case
  doctest JS2E.Parsers.TypeReferenceParser, import: true

  alias JS2E.Types.TypeReference
  alias JS2E.Parsers.TypeReferenceParser

  test "parse type reference" do

    type_dict =
      ~S"""
      {
        "$ref": "#/definitions/targetTypeId"
      }
      """
      |> Poison.decode!()
      |> TypeReferenceParser.parse(nil, nil, ["#", "typeRef"], "typeRef")

    expected_type_reference = %TypeReference{
      name: "typeRef",
      path: ["#", "definitions", "targetTypeId"]}

    assert type_dict == %{"#/typeRef" => expected_type_reference}
  end

end
