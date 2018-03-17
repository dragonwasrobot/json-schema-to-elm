defmodule JS2E.Printer.AllOfPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc ~S"""
  A printer for printing an 'all of' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer.{Util, PrinterResult}
  alias JS2E.{TypePath, Types}
  alias JS2E.Types.{AllOfType, SchemaDefinition}

  @templates_location Application.get_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "all_of/type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :type_name,
    :fields
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %AllOfType{name: name, path: path, types: types},
        schema_def,
        schema_dict,
        module_name
      ) do
    type_name = Util.upcase_first(name)

    {type_fields, errors} =
      types
      |> create_type_fields(path, schema_def, schema_dict, module_name)
      |> Util.split_ok_and_errors()

    type_name
    |> type_template(type_fields)
    |> PrinterResult.new(errors)
  end

  @spec create_type_fields(
          [TypePath.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_type_fields(types, parent, schema_def, schema_dict, module_name) do
    types
    |> Enum.map(
      &create_type_field(&1, parent, schema_def, schema_dict, module_name)
    )
  end

  @spec create_type_field(
          TypePath.t(),
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_type_field(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    field_type_result =
      type_path
      |> Util.resolve_type(parent, schema_def, schema_dict)
      |> Util.create_type_name(schema_def, module_name)

    case field_type_result do
      {:ok, field_type} ->
        field_name = Util.downcase_first(field_type)
        {:ok, %{name: field_name, type: field_type}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "all_of/decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :decoder_name,
    :type_name,
    :clauses
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %AllOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {clauses, errors} =
      type_paths
      |> create_decoder_clauses(path, schema_def, schema_dict, module_name)
      |> Util.split_ok_and_errors()

    decoder_name = "#{name}Decoder"
    type_name = Util.upcase_first(name)

    decoder_name
    |> decoder_template(type_name, clauses)
    |> PrinterResult.new(errors)
  end

  @spec create_decoder_clauses(
          [TypePath.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, map} | {:error, PrinterError.t()}]
  defp create_decoder_clauses(
         type_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_paths
    |> Enum.map(
      &create_decoder_property(&1, parent, schema_def, schema_dict, module_name)
    )
  end

  @spec create_decoder_property(
          TypePath.t(),
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp create_decoder_property(
         type_path,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    with {:ok, {property_type, resolved_schema_def}} <-
           Util.resolve_type(type_path, parent, schema_def, schema_dict),
         {:ok, decoder_name} <-
           Util.create_decoder_name(
             {:ok, {property_type, resolved_schema_def}},
             schema_def,
             module_name
           ) do
      property_name = property_type.name

      cond do
        Util.union_type?(property_type) or Util.one_of_type?(property_type) ->
          create_decoder_union_clause(property_name, decoder_name)

        Util.enum_type?(property_type) ->
          case Util.determine_primitive_type_decoder(property_type.type) do
            {:ok, property_type_decoder} ->
              create_decoder_enum_clause(
                property_name,
                property_type_decoder,
                decoder_name
              )

            {:error, error} ->
              {:error, error}
          end

        true ->
          create_decoder_normal_clause(property_name, decoder_name)
      end
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec create_decoder_union_clause(String.t(), String.t()) :: {:ok, map}
  defp create_decoder_union_clause(property_name, decoder_name) do
    {:ok, %{property_name: property_name, decoder_name: decoder_name}}
  end

  @spec create_decoder_enum_clause(String.t(), String.t(), String.t()) ::
          {:ok, map}
  defp create_decoder_enum_clause(
         property_name,
         property_type_decoder,
         decoder_name
       ) do
    {:ok,
     %{
       property_name: property_name,
       property_decoder: property_type_decoder,
       decoder_name: decoder_name
     }}
  end

  @spec create_decoder_normal_clause(String.t(), String.t()) :: {:ok, map}
  defp create_decoder_normal_clause(property_name, decoder_name) do
    {:ok, %{property_name: property_name, decoder_name: decoder_name}}
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "all_of/encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :encoder_name,
    :type_name,
    :argument_name,
    :properties
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %AllOfType{name: name, path: path, types: type_paths},
        schema_def,
        schema_dict,
        module_name
      ) do
    {properties, errors} =
      type_paths
      |> create_encoder_properties(path, schema_def, schema_dict, module_name)
      |> Util.split_ok_and_errors()

    type_name = Util.upcase_first(name)
    encoder_name = "encode#{type_name}"
    argument_name = Util.downcase_first(type_name)

    encoder_name
    |> encoder_template(type_name, argument_name, properties)
    |> Util.trim_newlines()
    |> PrinterResult.new(errors)
  end

  @spec create_encoder_properties(
          [TypePath.t()],
          TypePath.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: [{:ok, [map]} | {:error, PrinterError.t()}]
  defp create_encoder_properties(
         type_paths,
         parent,
         schema_def,
         schema_dict,
         module_name
       ) do
    type_paths
    |> Enum.map(&Util.resolve_type(&1, parent, schema_def, schema_dict))
    |> Enum.map(&to_encoder_property(&1, schema_def, module_name))
  end

  @spec to_encoder_property(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, map} | {:error, PrinterError.t()}
  defp to_encoder_property({:error, error}, _sf, _md), do: {:error, error}

  defp to_encoder_property({:ok, {property, schema}}, schema_def, module_name) do
    case Util.create_encoder_name(
           {:ok, {property, schema}},
           schema_def,
           module_name
         ) do
      {:ok, encoder_name} ->
        updated_property = Map.put(property, :encoder_name, encoder_name)
        {:ok, updated_property}

      {:error, error} ->
        {:error, error}
    end
  end
end
