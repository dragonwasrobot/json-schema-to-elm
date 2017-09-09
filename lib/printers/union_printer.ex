defmodule JS2E.Printers.UnionPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @type_location Path.join(@templates_location, "union/type.elm.eex")
  @decoder_location Path.join(@templates_location, "union/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "union/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.{UnionType, SchemaDefinition}

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :clauses])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :decoder_type, :nullable?, :clauses])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :cases])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_type(%UnionType{name: name,
                            path: _path,
                            types: types}, _schema_def, _schema_dict) do

    type_name = upcase_first name
    clauses = create_type_clauses(types, name)

    type_template(type_name, clauses)
  end

  @spec create_type_clauses([TypePath.t], String.t) :: [map]
  defp create_type_clauses(types, name) do

    type_name = upcase_first name

    to_clause = fn type ->
      case type do
        "boolean" ->
          %{name: "#{type_name}_B",
            type: "Bool"}

        "integer" ->
          %{name: "#{type_name}_I",
            type: "Int"}

        "number" ->
          %{name: "#{type_name}_F",
            type: "Float"}

        "string" ->
          %{name: "#{type_name}_S",
            type: "String"}
      end
    end

    types
    |> Enum.filter(&(&1 != "null"))
    |> Enum.map(to_clause)
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_decoder(%UnionType{name: name,
                               path: _path,
                               types: types}, _schema_def, _schema_dict) do

    type_name = upcase_first name
    nullable? = "null" in types

    decoder_name = "#{name}Decoder"
    decoder_type = (if nullable? do
      "(Maybe #{type_name})"
    else
      type_name
    end)

    clauses = create_clause_decoders(types, type_name, nullable?)

    decoder_template(decoder_name, decoder_type, nullable?, clauses)
  end

  @spec create_clause_decoders([String.t], String.t, boolean) :: [map]
  defp create_clause_decoders(types, type_name, nullable?) do

    types
    |> Enum.filter(fn type -> type != "null" end)
    |> Enum.map(fn type ->
      create_clause_decoder(type, type_name, nullable?)
    end)
  end

  @spec create_clause_decoder(String.t, String.t, boolean) :: map
  defp create_clause_decoder(type, type_name, nullable?) do

    {constructor_suffix, decoder_name} =
      case type do
        "boolean" ->
          {"_B", "Decode.bool"}

        "integer" ->
          {"_I", "Decode.int"}

        "number" ->
          {"_F", "Decode.float"}

        "string" ->
          {"_S", "Decode.string"}
      end

    constructor_name = type_name <> constructor_suffix

    wrapper = if nullable? do "succeed << Just" else "succeed" end
    %{decoder_name: decoder_name,
      constructor_name: constructor_name,
      wrapper: wrapper}
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_encoder(%UnionType{name: name,
                              path: _path,
                              types: types}, _schema_def, _schema_dict) do

    type_name = upcase_first name
    encoder_name = "encode#{type_name}"
    cases = create_encoder_cases(types, name)

    template = encoder_template(encoder_name, type_name, name, cases)
    trim_newlines(template)
  end

  @spec create_encoder_cases([String.t], String.t) :: [map]
  defp create_encoder_cases(types, name) do
    types |> Enum.map(fn type ->
      create_encoder_clause(type, name)
    end)
  end

  @spec create_encoder_clause(String.t, String.t) :: map
  defp create_encoder_clause(type, name) do

    {constructor_suffix, encoder_name, argument_name} =
      case type do
        "boolean" ->
          {"_B", "Encode.bool", "boolValue"}

        "integer" ->
          {"_I", "Encode.int", "intValue"}

        "number" ->
          {"_F", "Encode.float", "floatValue"}

        "string" ->
          {"_S", "Encode.string", "stringValue"}
      end

    constructor_name = (upcase_first name) <> constructor_suffix

    %{constructor: "#{constructor_name} #{argument_name}",
      encoder: "#{encoder_name} #{argument_name}"}
  end

end
