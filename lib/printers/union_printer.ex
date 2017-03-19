defmodule JS2E.Printers.UnionPrinter do
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Logger
  alias JS2E.{TypePath, Types}
  alias JS2E.Printers.Util
  alias JS2E.Types.UnionType

  @spec print_type(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%UnionType{name: name,
                            path: _path,
                            types: types}, _type_dict, _schema_dict) do

    indent = Util.indent
    type_name = Util.upcase_first name
    clauses = print_type_clauses(types, name)

    """
    type #{type_name}
    #{indent}= #{clauses}
    """
  end

  @spec print_type_clauses([TypePath.t], String.t) :: String.t
  defp print_type_clauses(types, name) do

    type_name = Util.upcase_first name

    to_clause = fn type ->
      case type do
        "null" ->
          ""

        "boolean" ->
          "#{type_name}_B Bool"

        "integer" ->
          "#{type_name}_I Int"

        "number" ->
          "#{type_name}_F Float"

        "string" ->
          "#{type_name}_S String"
      end
    end

    indent = Util.indent

    types
    |> Enum.filter(fn x -> x != "null" end)
    |> Enum.map_join("\n#{indent}| ", to_clause)
  end

  @spec print_decoder(
    Types.typeDefinition,
    Types.typeDictionary,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%UnionType{name: name,
                               path: _path,
                               types: types}, _type_dict, _schema_dict) do

    indent = Util.indent
    type_name = Util.upcase_first name
    nullable? = "null" in types

    decoder_type = (if nullable? do
      "(Maybe #{type_name})"
    else
      type_name
    end)

    clause_decoders = print_clause_decoders(types, type_name, nullable?)

    """
    #{name}Decoder : Decoder #{decoder_type}
    #{name}Decoder =
    #{indent}oneOf [ #{clause_decoders}
    #{indent}      ]
    """
  end

  @spec print_clause_decoders([String.t], String.t, boolean) :: String.t
  defp print_clause_decoders(types, type_name, nullable?) do
    indent = Util.indent

    add_null_clause = fn printed_clause_decoders ->
      if nullable? do
        printed_clause_decoders <> "\n#{indent}      , null Nothing"
      else
        printed_clause_decoders
      end
    end

    types
    |> Enum.filter(fn type -> type != "null" end)
    |> Enum.map_join("\n#{indent}      , ", fn type ->
      print_clause_decoder(type, nullable?, type_name)
    end)
    |> add_null_clause.()
  end

  @spec print_clause_decoder(String.t, boolean, String.t) :: String.t
  defp print_clause_decoder(type, nullable?, type_name) do

    {constructor_suffix, decoder_name} =
      case type do
        "boolean" ->
          {"_B", "bool"}

        "integer" ->
          {"_I", "int"}

        "number" ->
          {"_F", "float"}

        "string" ->
          {"_S", "string"}
      end

    constructor_name = type_name <> constructor_suffix

    if nullable? do
      "#{decoder_name} |> andThen (succeed << Just << #{constructor_name})"
    else
      "#{decoder_name} |> andThen (succeed << #{constructor_name})"
    end
  end

end
