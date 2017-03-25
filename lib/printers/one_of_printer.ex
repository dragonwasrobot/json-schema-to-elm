defmodule JS2E.Printers.OneOfPrinter do
  @moduledoc """
  A printer for printing a 'one of' type decoder.
  """

  require Logger
  alias JS2E.{Printer, TypePath, Types}
  alias JS2E.Printers.Util
  alias JS2E.Types.OneOfType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%OneOfType{name: name,
                            path: _path,
                            types: types}, type_dict, schema_dict) do

    indent = Util.indent
    clauses = print_type_clauses(types, name, type_dict, schema_dict)
    type_name = Util.upcase_first name

    """
    type #{type_name}
    #{indent}= #{clauses}
    """
  end

  @spec print_type_clauses(
    [TypePath.t],
    String.t,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  defp print_type_clauses(types, name, type_dict, schema_dict) do

    type_name = Util.upcase_first name

    print_type_clause = fn type_path ->
      clause_type =
        type_path
        |> Printer.resolve_type(type_dict, schema_dict)

      type_value = Util.upcase_first clause_type.name

      type_prefix =
        type_value
        |> String.slice(0..1)
        |> String.capitalize

      "#{type_name}_#{type_prefix} #{type_value}"
    end

    indent = Util.indent

    types
    |> Enum.map_join("\n#{indent}| ", print_type_clause)
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%OneOfType{name: name,
                               path: _path,
                               types: types}, type_dict, schema_dict) do

    decoder_type = Util.upcase_first name
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
    indent = Util.indent

    print_decoder_clause = fn type_path ->
      clause_type =
        type_path
        |> Printer.resolve_type(type_dict, schema_dict)

      "#{clause_type.name}Decoder"
    end

    types
    |> Enum.map_join("\n#{indent}      , ", print_decoder_clause)
  end

end
