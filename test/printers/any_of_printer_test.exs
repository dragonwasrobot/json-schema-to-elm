defmodule JS2ETest.Printers.AnyOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{AnyOfType, ObjectType, TypeReference}
  alias JS2E.Printers.AnyOfPrinter

  test "print 'any of' type value" do

    type_dict = %{
      "#/shape/0" =>
      %TypeReference{name: "square",
                     path: ["#", "definitions", "square"]},

      "#/shape/1" =>
        %TypeReference{name: "circle",
                       path: ["#", "definitions", "circle"]},

      "#/definitions/square" =>
        %ObjectType{name: "square",
                    path: ["#"],
                    required: ["color", "size"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    any_of_type_program =
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "shape", "0"],
                ["#", "shape", "1"]]
      }
      |> AnyOfPrinter.print_type(type_dict, %{})

    expected_any_of_type_program =
      """
      type alias Shape =
          { square : Maybe Square
          , circle : Maybe Circle
          }
      """

    assert any_of_type_program == expected_any_of_type_program
  end

  test "print 'any of' decoder" do

    type_dict = %{
      "#/definitions/square" =>
      %ObjectType{name: "square",
                  path: ["#"],
                  required: ["color", "size"],
                  properties: %{"color" => ["#", "properties", "color"],
                                "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    any_of_decoder_program =
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> AnyOfPrinter.print_decoder(type_dict, %{})

    expected_any_of_decoder_program =
    """
    shapeDecoder : Decoder Shape
    shapeDecoder =
        decode Shape
            |> optional "square" (nullable squareDecoder) Nothing
            |> optional "circle" (nullable circleDecoder) Nothing
    """

    assert any_of_decoder_program == expected_any_of_decoder_program
  end

  test "print 'any of' encoder" do

    type_dict = %{
      "#/definitions/square" =>
      %ObjectType{name: "square",
                  path: ["#"],
                  required: ["color", "size"],
                  properties: %{"color" => ["#", "properties", "color"],
                                "title" => ["#", "properties", "size"]}},

      "#/definitions/circle" =>
        %ObjectType{name: "circle",
                    path: ["#"],
                    required: ["color", "radius"],
                    properties: %{"color" => ["#", "properties", "color"],
                                  "radius" => ["#", "properties", "radius"]}}
    }

    any_of_encoder_program =
      %AnyOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> AnyOfPrinter.print_encoder(type_dict, %{})

    expected_any_of_encoder_program =
    """
    encodeShape : Shape -> Value
    encodeShape shape =
        let
            square =
                case shape.square of
                    Just square ->
                        encodeSquare square

                    Nothing ->
                        []

            circle =
                case shape.circle of
                    Just circle ->
                        encodeCircle circle

                    Nothing ->
                        []
        in
            object <|
                square ++ circle
    """

    assert any_of_encoder_program == expected_any_of_encoder_program
  end

end
