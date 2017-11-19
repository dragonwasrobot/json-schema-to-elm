defmodule JS2E.Printers.OneOfPrinter do
  @behaviour JS2E.Printers.PrinterBehaviour
  @moduledoc """
  A printer for printing a 'one of' type decoder.
  """

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util, only: [
    resolve_type: 4,
    split_ok_and_errors: 1,
    trim_newlines: 1,
    upcase_first: 1
  ]
  alias JS2E.Printers.PrinterResult
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.{OneOfType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "one_of/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :clauses])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_type(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: PrinterResult.t
  def print_type(%OneOfType{name: name,
                            path: path,
                            types: types},
    schema_def, schema_dict, _module_name) do

    type_name = upcase_first name

    {type_clauses, errors} =
      types
      |> create_type_clauses(name, path, schema_def, schema_dict)
      |> split_ok_and_errors()

    type_name
    |> type_template(type_clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_type_clauses(
    [TypePath.t],
    String.t,
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_type_clauses(type_clauses, name, parent, schema_def, schema_dict) do
    type_clauses
    |> Enum.map(&(create_type_clause(&1, name, parent,
            schema_def, schema_dict)))
  end

  @spec create_type_clause(
    TypePath.t,
    String.t,
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: {:ok, map} | {:error, PrinterError.t}
  defp create_type_clause(type_clause_id, name, parent, schema_def, schema_dict) do

    case resolve_type(type_clause_id, parent, schema_def, schema_dict) do
      {:ok, {type_clause, _resolved_schema_def}} ->

        type_value = upcase_first type_clause.name

        type_prefix =
          type_value
          |> String.slice(0..1)
          |> String.capitalize

        type_name = upcase_first name

        {:ok, %{name: "#{type_name}_#{type_prefix}",
                type: type_value}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "one_of/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :decoder_type, :clause_decoders])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_decoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: PrinterResult.t
  def print_decoder(%OneOfType{name: name,
                               path: path,
                               types: types},
    schema_def, schema_dict, _module_name) do

    {clause_decoders, errors} =
      types
      |> create_decoder_clauses(path, schema_def, schema_dict)
      |> split_ok_and_errors()

    decoder_name = "#{name}Decoder"
    decoder_type = upcase_first name

    decoder_name
    |> decoder_template(decoder_type, clause_decoders)
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_clauses(
    [TypePath.t],
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [{:ok, String.t} | {:error, PrinterError.t}]
  defp create_decoder_clauses(type_clauses, parent, schema_def, schema_dict) do

    type_clauses
    |> Enum.map(&(create_decoder_clause(&1,
            parent, schema_def, schema_dict)))
  end

  @spec create_decoder_clause(
    TypePath.t,
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary)
  :: {:ok, String.t} | {:error, PrinterError.t}
  defp create_decoder_clause(type_clause_id, parent, schema_def, schema_dict) do

    case resolve_type(type_clause_id, parent, schema_def, schema_dict) do
      {:ok, {clause_type, _resolved_schema_def}} ->
        {:ok, "#{clause_type.name}Decoder"}

      {:error, error} ->
        {:error, error}
    end
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "one_of/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :cases])

  @impl JS2E.Printers.PrinterBehaviour
  @spec print_encoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary,
    String.t
  ) :: PrinterResult.t
  def print_encoder(%OneOfType{name: name,
                              path: path,
                              types: types},
    schema_def, schema_dict, _module_name) do

    {encoder_cases, errors} =
      types
      |> create_encoder_cases(name, path, schema_def, schema_dict)
      |> split_ok_and_errors()

    type_name = upcase_first name
    encoder_name = "encode#{type_name}"

    encoder_name
    |> encoder_template(type_name, name, encoder_cases)
    |> trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_cases(
    [String.t],
    String.t,
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [{:ok, map} | {:error, PrinterError.t}]
  defp create_encoder_cases(types, name, parent, schema_def, schema_dict) do

    types
    |> Enum.map(&(create_encoder_clause(&1, name, parent,
            schema_def, schema_dict)))
  end

  @spec create_encoder_clause(
    String.t,
    String.t,
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: {:ok, map} | {:error, PrinterError.t}
  defp create_encoder_clause(type_path, name, parent, schema_def, schema_dict) do

    case resolve_type(type_path, parent, schema_def, schema_dict) do
      {:ok, {clause_type, _resolved_schema_def}} ->

        type_name = upcase_first name
        argument_name = clause_type.name
        type_value = upcase_first argument_name

        type_prefix =
          type_value
          |> String.slice(0..1)
          |> String.capitalize

        {:ok, %{constructor: "#{type_name}_#{type_prefix} #{argument_name}",
                encoder: "encode#{type_value} #{argument_name}"}}

      {:error, error} ->
        {:error, error}
    end
  end

end
