defmodule JS2ETest.Printers.OneOfPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{OneOfType, ObjectType, TypeReference}
  alias JS2E.Printers.OneOfPrinter

  test "print 'one of' type value" do

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

    one_of_type_program =
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "shape", "0"],
                ["#", "shape", "1"]]
      }
      |> OneOfPrinter.print_type(type_dict, %{})

    expected_one_of_type_program =
      """
      type Shape
          = Shape_Sq Square
          | Shape_Ci Circle
      """

    assert one_of_type_program == expected_one_of_type_program
  end

  test "print 'one of' decoder" do

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

    one_of_decoder_program =
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> OneOfPrinter.print_decoder(type_dict, %{})

    expected_one_of_decoder_program =
    """
    shapeDecoder : Decoder Shape
    shapeDecoder =
        oneOf [ squareDecoder
              , circleDecoder
              ]
    """

    assert one_of_decoder_program == expected_one_of_decoder_program
  end

  test "print 'one of' encoder" do

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

    one_of_encoder_program =
      %OneOfType{
        name: "shape",
        path: ["#", "definitions", "shape"],
        types: [["#", "definitions", "square"],
                ["#", "definitions", "circle"]]
      }
      |> OneOfPrinter.print_encoder(type_dict, %{})

    expected_one_of_encoder_program =
    """
    encodeShape : Shape -> Value
    encodeShape shape =
        case shape of
            Shape_Sq square ->
                encodeSquare square

            Shape_Ci circle ->
                encodeCircle circle
    """

    assert one_of_encoder_program == expected_one_of_encoder_program
  end

end
