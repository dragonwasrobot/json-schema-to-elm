defmodule JS2E.Printers.OneOfPrinter do
  @moduledoc """
  A printer for printing a 'one of' type decoder.
  """

  require Logger
  import JS2E.Printers.Util
  alias JS2E.{Printer, TypePath, Types}
  alias JS2E.Types.OneOfType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%OneOfType{name: name,
                            path: _path,
                            types: types}, type_dict, schema_dict) do
    clauses = print_type_clauses(types, name, type_dict, schema_dict)
    type_name = upcase_first name

    """
    type #{type_name}
    #{indent()}= #{clauses}
    """
  end

  @spec print_type_clauses(
    [TypePath.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_type_clauses(types, name, type_dict, schema_dict) do

    type_name = upcase_first name

    print_type_clause = fn type_path ->
      clause_type =
        type_path
        |> Printer.resolve_type(type_dict, schema_dict)

      type_value = upcase_first clause_type.name

      type_prefix =
        type_value
        |> String.slice(0..1)
        |> String.capitalize

      "#{type_name}_#{type_prefix} #{type_value}"
    end

    types
    |> Enum.map_join("\n#{indent()}| ", print_type_clause)
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%OneOfType{name: name,
                               path: _path,
                               types: types}, type_dict, schema_dict) do

    decoder_type = upcase_first name
    clause_decoders = print_decoder_clauses(types, type_dict, schema_dict)

    """
    #{name}Decoder : Decoder #{decoder_type}
    #{name}Decoder =
        oneOf [ #{clause_decoders}
              ]
    """
  end

  @spec print_decoder_clauses(
    [TypePath.t],
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_decoder_clauses(types, type_dict, schema_dict) do

    print_decoder_clause = fn type_path ->
      clause_type =
        type_path
        |> Printer.resolve_type(type_dict, schema_dict)

      "#{clause_type.name}Decoder"
    end

    types
    |> Enum.map_join("\n#{indent()}      , ", print_decoder_clause)
  end

  @spec print_encoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%OneOfType{name: name,
                              path: _path,
                              types: types}, type_dict, schema_dict) do

    declaration = print_encoder_declaration(name)
    cases = print_encoder_cases(types, name, type_dict, schema_dict)

    declaration <> cases
  end

  @spec print_encoder_declaration(String.t) :: String.t
  defp print_encoder_declaration(name) do
    type_name = upcase_first name
    encoder_name = "encode#{type_name}"

    """
    #{encoder_name} : #{type_name} -> Value
    #{encoder_name} #{name} =
    #{indent()}case #{name} of
    """
  end

  @spec print_encoder_cases(
    [String.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_encoder_cases(types, name, type_dict, schema_dict) do

    Enum.map_join(types, "\n", fn type ->

      {printed_elm_value, printed_json_value} =
        print_encoder_clause(type, name, type_dict, schema_dict)

      "#{indent(2)}#{printed_elm_value} ->\n" <>
        "#{indent(3)}#{printed_json_value}\n"
    end)
  end

  @spec print_encoder_clause(
    String.t,
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: {String.t, String.t}
  defp print_encoder_clause(type_path, name, type_dict, schema_dict) do

    type_name = upcase_first name

    print_type_clause = fn type_path ->
      clause_type =
        type_path
        |> Printer.resolve_type(type_dict, schema_dict)

      argument_name = clause_type.name
      type_value = upcase_first argument_name

      type_prefix =
        type_value
        |> String.slice(0..1)
        |> String.capitalize

      {"#{type_name}_#{type_prefix} #{argument_name}",
       "encode#{type_value} #{argument_name}"}
    end

    print_type_clause.(type_path)
  end

end
