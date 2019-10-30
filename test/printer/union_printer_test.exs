defmodule JS2ETest.Printer.UnionPrinter do
  use ExUnit.Case

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.UnionPrinter
  alias Types.{SchemaDefinition, UnionType}

  test "print union type value" do
    result =
      union_type()
      |> UnionPrinter.print_type(schema_def(), %{}, module_name())

    expected_union_type_program = """
    type FavoriteNumber
        = FavoriteNumber_F Float
        | FavoriteNumber_I Int
    """

    union_type_program = result.printed_schema

    assert union_type_program == expected_union_type_program
  end

  test "print union type with null value" do
    result =
      union_type_with_null()
      |> UnionPrinter.print_type(schema_def(), %{}, module_name())

    expected_union_type_program = """
    type FavoriteNumber
        = FavoriteNumber_F Float
        | FavoriteNumber_I Int
    """

    union_type_program = result.printed_schema

    assert union_type_program == expected_union_type_program
  end

  test "print union decoder" do
    result =
      union_type()
      |> UnionPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_union_decoder_program = """
    favoriteNumberDecoder : Decoder FavoriteNumber
    favoriteNumberDecoder =
        oneOf [ Decode.float |> andThen (succeed << FavoriteNumber_F)
              , Decode.int |> andThen (succeed << FavoriteNumber_I)
              ]
    """

    union_decoder_program = result.printed_schema

    assert union_decoder_program == expected_union_decoder_program
  end

  test "print union decoder with null value" do
    result =
      union_type_with_null()
      |> UnionPrinter.print_decoder(schema_def(), %{}, module_name())

    expected_union_decoder_program = """
    favoriteNumberDecoder : Decoder (Maybe FavoriteNumber)
    favoriteNumberDecoder =
        oneOf [ Decode.float |> andThen (succeed << Just << FavoriteNumber_F)
              , Decode.int |> andThen (succeed << Just << FavoriteNumber_I)
              , null Nothing
              ]
    """

    union_decoder_program = result.printed_schema

    assert union_decoder_program == expected_union_decoder_program
  end

  test "print union encoder" do
    result =
      union_type()
      |> UnionPrinter.print_encoder(schema_def(), %{}, module_name())

    expected_union_encoder_program = """
    encodeFavoriteNumber : FavoriteNumber -> Value
    encodeFavoriteNumber favoriteNumber =
        case favoriteNumber of
            FavoriteNumber_F floatValue ->
                Encode.float floatValue

            FavoriteNumber_I intValue ->
                Encode.int intValue
    """

    union_encoder_program = result.printed_schema

    assert union_encoder_program == expected_union_encoder_program
  end

  test "print union fuzzer" do
    result =
      union_type()
      |> UnionPrinter.print_fuzzer(schema_def(), %{}, module_name())

    expected_union_fuzzer = """
    favoriteNumberFuzzer : Fuzzer FavoriteNumber
    favoriteNumberFuzzer =
        Fuzz.map
            [ Fuzz.float
            , Fuzz.int
            ]


    encodeDecodeFavoriteNumberTest : Test
    encodeDecodeFavoriteNumberTest =
        fuzz favoriteNumberFuzzer "can encode and decode FavoriteNumber union" <|
            \\favoriteNumber ->
                favoriteNumber
                    |> encodeFavoriteNumber
                    |> Decode.decodeValue favoriteNumberDecoder
                    |> Expect.equal (Ok favoriteNumber)
    """

    union_fuzzer = result.printed_schema

    assert union_fuzzer == expected_union_fuzzer
  end

  defp module_name, do: "Domain"

  defp schema_def,
    do: %SchemaDefinition{
      description: "Test schema",
      id: URI.parse("http://example.com/test.json"),
      file_path: "test.json",
      title: "Test",
      types: %{}
    }

  defp union_type,
    do: %UnionType{
      name: "favoriteNumber",
      path: ["#", "definitions", "favoriteNumber"],
      types: ["number", "integer"]
    }

  defp union_type_with_null,
    do: %UnionType{
      name: "favoriteNumber",
      path: ["#", "definitions", "favoriteNumber"],
      types: ["number", "integer", "null"]
    }
end
