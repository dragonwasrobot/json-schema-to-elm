defmodule JS2ETest.Printers.UnionPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Types.UnionType
  alias JS2E.Printers.UnionPrinter

  test "print union type value" do

    type_dict = %{}

    union_type_program =
      %UnionType{
        name: "favoriteNumber",
        path: ["#", "definitions", "favoriteNumber"],
        types: ["number", "integer"]
      }
      |> UnionPrinter.print_type(type_dict, %{})

    expected_union_type_program =
      """
      type FavoriteNumber
          = FavoriteNumber_F Float
          | FavoriteNumber_I Int
      """

    assert union_type_program == expected_union_type_program
  end

  test "print union type with null value" do

    type_dict = %{}

    union_type_program =
      %UnionType{
        name: "favoriteNumber",
        path: ["#", "definitions", "favoriteNumber"],
        types: ["number", "integer", "null"]
      }
      |> UnionPrinter.print_type(type_dict, %{})

    expected_union_type_program =
    """
    type FavoriteNumber
        = FavoriteNumber_F Float
        | FavoriteNumber_I Int
    """

    assert union_type_program == expected_union_type_program
  end

  test "print union decoder" do

    type_dict = %{}

    union_decoder_program =
      %UnionType{
        name: "favoriteNumber",
        path: ["#", "definitions", "favoriteNumber"],
        types: ["number", "integer"]
      }
      |> UnionPrinter.print_decoder(type_dict, %{})

    expected_union_decoder_program =
    """
    favoriteNumberDecoder : Decoder FavoriteNumber
    favoriteNumberDecoder =
        oneOf [ Decode.float |> andThen (succeed << FavoriteNumber_F)
              , Decode.int |> andThen (succeed << FavoriteNumber_I)
              ]
    """

    assert union_decoder_program == expected_union_decoder_program
  end

  test "print union decoder with null value" do

    type_dict = %{}

    union_decoder_program =
      %UnionType{
        name: "favoriteNumber",
        path: ["#", "definitions", "favoriteNumber"],
        types: ["number", "integer", "null"]
      }
      |> UnionPrinter.print_decoder(type_dict, %{})

    expected_union_decoder_program =
    """
    favoriteNumberDecoder : Decoder (Maybe FavoriteNumber)
    favoriteNumberDecoder =
        oneOf [ Decode.float |> andThen (succeed << Just << FavoriteNumber_F)
              , Decode.int |> andThen (succeed << Just << FavoriteNumber_I)
              , null Nothing
              ]
    """

    assert union_decoder_program == expected_union_decoder_program
  end

  test "print union encoder" do

    type_dict = %{}

    union_encoder_program =
      %UnionType{
        name: "favoriteNumber",
        path: ["#", "definitions", "favoriteNumber"],
        types: ["number", "integer"]
      }
      |> UnionPrinter.print_encoder(type_dict, %{})

    expected_union_encoder_program =
    """
    encodeFavoriteNumber : FavoriteNumber -> Value
    encodeFavoriteNumber favoriteNumber =
        case favoriteNumber of
            FavoriteNumber_F floatValue ->
                Encode.float floatValue

            FavoriteNumber_I intValue ->
                Encode.int intValue
    """

    assert union_encoder_program == expected_union_encoder_program
  end

end
