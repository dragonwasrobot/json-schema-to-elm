defmodule JS2E.Printers.OneOfPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing a 'one of' type decoder.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @type_location Path.join(@templates_location, "one_of/type.elm.eex")
  @decoder_location Path.join(@templates_location, "one_of/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "one_of/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.{Printer, TypePath, Types}
  alias JS2E.Types.{OneOfType, SchemaDefinition}

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :clauses])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :decoder_type, :clause_decoders])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :cases])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_type(%OneOfType{name: name,
                            path: _path,
                            types: types}, schema_def, schema_dict) do

    type_name = upcase_first name
    clauses = create_type_clauses(types, name, schema_def, schema_dict)

    type_template(type_name, clauses)
  end

  @spec create_type_clauses(
    [TypePath.t],
    String.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_type_clauses(types, name, schema_def, schema_dict) do

    type_name = upcase_first name

    create_type_clause = fn type_path ->
      {clause_type, _resolved_schema_def} =
        type_path
        |> Printer.resolve_type!(schema_def, schema_dict)

      type_value = upcase_first clause_type.name

      type_prefix =
        type_value
        |> String.slice(0..1)
        |> String.capitalize

      %{name: "#{type_name}_#{type_prefix}",
        type: type_value}
    end

    types
    |> Enum.map(create_type_clause)
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_decoder(%OneOfType{name: name,
                               path: _path,
                               types: types}, schema_def, schema_dict) do

    decoder_name = "#{name}Decoder"
    decoder_type = upcase_first name
    clause_decoders = create_decoder_clauses(types, schema_def, schema_dict)

    decoder_template(decoder_name, decoder_type, clause_decoders)
  end

  @spec create_decoder_clauses(
    [TypePath.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [String.t]
  defp create_decoder_clauses(types, schema_def, schema_dict) do

    create_decoder_clause = fn type_path ->
      {clause_type, _resolved_schema_def} =
        type_path
        |> Printer.resolve_type!(schema_def, schema_dict)

      "#{clause_type.name}Decoder"
    end

    types
    |> Enum.map(create_decoder_clause)
  end

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(Types.typeDefinition, SchemaDefinition.t,
    Types.schemaDictionary) :: String.t
  def print_encoder(%OneOfType{name: name,
                              path: _path,
                              types: types}, schema_def, schema_dict) do

    type_name = upcase_first name
    encoder_name = "encode#{type_name}"
    cases = create_encoder_cases(types, name, schema_def, schema_dict)

    template = encoder_template(encoder_name, type_name, name, cases)
    trim_newlines(template)
  end

  @spec create_encoder_cases(
    [String.t],
    String.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_encoder_cases(types, name, schema_def, schema_dict) do

    types |> Enum.map(fn type ->
      create_encoder_clause(type, name, schema_def, schema_dict)
    end)
  end

  @spec create_encoder_clause(
    String.t,
    String.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_encoder_clause(type_path, name, schema_def, schema_dict) do

    type_name = upcase_first name

    create_type_clause = fn type_path ->
      {clause_type, _resolved_schema_def} =
        type_path
        |> Printer.resolve_type!(schema_def, schema_dict)

      argument_name = clause_type.name
      type_value = upcase_first argument_name

      type_prefix =
        type_value
        |> String.slice(0..1)
        |> String.capitalize

      %{constructor: "#{type_name}_#{type_prefix} #{argument_name}",
        encoder: "encode#{type_value} #{argument_name}"}
    end

    create_type_clause.(type_path)
  end

end
