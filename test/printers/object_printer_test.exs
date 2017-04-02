defmodule JS2ETest.Printers.ObjectPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.{ObjectType, EnumType, PrimitiveType}
  alias JS2E.Printers.ObjectPrinter

  test "print object type" do

    type_dict = %{
      "#/properties/color" =>
      %EnumType{name: "color",
                path: ["#", "properties", "color"],
                type: "string",
                values: ["none", "green", "yellow", "red"]},

      "#/properties/title" =>
        %PrimitiveType{name: "title",
                       path: ["#", "properties", "title"],
                       type: "string"},

      "#/properties/radius" =>
        %PrimitiveType{name: "radius",
                       path: ["#", "properties", "radius"],
                       type: "number"}
    }

    object_type_program =
      %ObjectType{
        name: "circle",
        path: "#",
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "title"],
          "radius" => ["#", "properties", "radius"]}
      }
      |> ObjectPrinter.print_type(type_dict, %{})

    expected_object_type_program =
    """
    type alias Circle =
        { color : Color
        , radius : Float
        , title : Maybe String
        }
    """

    assert object_type_program == expected_object_type_program
  end

  test "print object decoder" do

    type_dict = %{
      "#/properties/color" =>
      %EnumType{name: "color",
                path: ["#", "properties", "color"],
                type: "string",
                values: ["none", "green", "yellow", "red"]},

      "#/properties/title" =>
        %PrimitiveType{name: "title",
                       path: ["#", "properties", "title"],
                       type: "string"},

      "#/properties/radius" =>
        %PrimitiveType{name: "radius",
                       path: ["#", "properties", "radius"],
                       type: "number"}
    }

    object_decoder_program =
      %ObjectType{
        name: "circle",
        path: "#",
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "title"],
          "radius" => ["#", "properties", "radius"]}
      }
      |> ObjectPrinter.print_decoder(type_dict, %{})

    expected_object_decoder_program =
    """
    circleDecoder : Decoder Circle
    circleDecoder =
        decode Circle
            |> required "color" (Decode.string |> andThen colorDecoder)
            |> required "radius" Decode.float
            |> optional "title" (nullable Decode.string) Nothing
    """

    assert object_decoder_program == expected_object_decoder_program
  end

  test "print object encoder" do

    type_dict = %{
      "#/properties/color" =>
      %EnumType{name: "color",
                path: ["#", "properties", "color"],
                type: "string",
                values: ["none", "green", "yellow", "red"]},

      "#/properties/title" =>
        %PrimitiveType{name: "title",
                       path: ["#", "properties", "title"],
                       type: "string"},

      "#/properties/radius" =>
        %PrimitiveType{name: "radius",
                       path: ["#", "properties", "radius"],
                       type: "number"}
    }

    object_encoder_program =
      %ObjectType{
        name: "circle",
        path: "#",
        required: ["color", "radius"],
        properties: %{
          "color" => ["#", "properties", "color"],
          "title" => ["#", "properties", "title"],
          "radius" => ["#", "properties", "radius"]}
      }
      |> ObjectPrinter.print_encoder(type_dict, %{})

    expected_object_encoder_program =
    """
    encodeCircle : Circle -> Value
    encodeCircle circle =
        let
            color =
                [ ( "color", encodeColor circle.color ) ]

            radius =
                [ ( "radius", Encode.float circle.radius ) ]

            title =
                case circle.title of
                    Just title ->
                        [ ( "title", Encode.string title ) ]

                    Nothing ->
                        []
        in
            object <|
                color ++ radius ++ title
    """

    assert object_encoder_program == expected_object_encoder_program
  end

end
