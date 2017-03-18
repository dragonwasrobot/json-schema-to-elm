defmodule JS2ETest.Parsers.TypeReferenceParser do
  use ExUnit.Case

  alias JS2E.Types.TypeReference
  alias JS2E.Parsers.TypeReferenceParser

  test "parse type reference" do

    type_dict =
      ~S"""
      {
        "$ref": "#/targetTypeId"
      }
      """
      |> Poison.decode!()
      |> TypeReferenceParser.parse(nil, ["#", "typeRef"], "typeRef")

    expected_type_reference = %TypeReference{
      name: "typeRef",
      path: ["#", "targetTypeId"]}

    assert type_dict == %{"#/typeRef" => expected_type_reference}
  end

end
