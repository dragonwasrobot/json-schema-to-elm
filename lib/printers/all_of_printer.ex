defmodule JS2E.Printers.AllOfPrinter do
  @moduledoc """
  A printer for printing an 'all of' type decoder.
  """

  @templates_location Application.get_env(:js2e, :templates_location)
  @type_location Path.join(@templates_location, "all_of/type.elm.eex")
  @decoder_location Path.join(@templates_location, "all_of/decoder.elm.eex")
  @encoder_location Path.join(@templates_location, "all_of/encoder.elm.eex")

  require Elixir.{EEx, Logger}
  import JS2E.Printers.Util
  alias JS2E.{Printer, TypePath, Types}
  alias JS2E.Types.{AllOfType, SchemaDefinition}

  EEx.function_from_file(:defp, :type_template, @type_location,
    [:type_name, :fields])

  EEx.function_from_file(:defp, :decoder_template, @decoder_location,
    [:decoder_name, :type_name, :clauses])

  EEx.function_from_file(:defp, :encoder_template, @encoder_location,
    [:encoder_name, :type_name, :argument_name, :properties])

  @spec print_type(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_type(%AllOfType{name: name,
                            path: _path,
                            types: types}, schema_def, schema_dict) do

    type_name = upcase_first name
    fields = create_type_fields(types, schema_def, schema_dict)

    type_template(type_name, fields)
  end

  @spec create_type_fields(
    [TypePath.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_type_fields(types, schema_def, schema_dict) do
    types |> Enum.map(&(create_type_field(&1, schema_def, schema_dict)))
  end

  @spec create_type_field(
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_type_field(type_path, schema_def, schema_dict) do

    field_type =
      type_path
      |> Printer.resolve_type!(schema_def, schema_dict)
      |> create_type_name(schema_def)

    field_name = downcase_first field_type

    %{name: field_name,
      type: field_type}
  end

  @spec print_decoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_decoder(%AllOfType{name: name,
                               path: _path,
                               types: type_paths},
    schema_def, schema_dict) do

    decoder_name = "#{name}Decoder"
    type_name = upcase_first name
    clauses = create_decoder_clauses(type_paths, schema_def, schema_dict)

    decoder_template(decoder_name, type_name, clauses)
  end

  @spec create_decoder_clauses(
    [TypePath.t],
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: [map]
  defp create_decoder_clauses(type_paths, schema_def, schema_dict) do

    type_paths
    |> Enum.map(fn type_path ->
      create_decoder_property(type_path, schema_def, schema_dict)
    end)
  end

  @spec create_decoder_property(
    TypePath.t,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: map
  defp create_decoder_property(type_path, schema_def, schema_dict) do

    {property_type, resolved_schema_def} =
      type_path
      |> Printer.resolve_type!(schema_def, schema_dict)

    property_name = property_type.name
    decoder_name = create_decoder_name(
      {property_type, resolved_schema_def}, schema_def)

    cond do
      union_type?(property_type) || one_of_type?(property_type) ->
        create_decoder_union_clause(property_name, decoder_name)

      enum_type?(property_type) ->
        property_type_decoder =
          property_type.type
          |> determine_primitive_type_decoder!()

        create_decoder_enum_clause(
          property_name, property_type_decoder, decoder_name)

      true ->
        create_decoder_normal_clause(property_name, decoder_name)
    end
  end

  defp create_decoder_union_clause(property_name, decoder_name) do
    %{property_name: property_name,
      decoder_name: decoder_name}
  end

  defp create_decoder_enum_clause(property_name,
    property_type_decoder, decoder_name) do

    %{property_name: property_name,
      property_decoder: property_type_decoder,
      decoder_name: decoder_name}
  end

  defp create_decoder_normal_clause(property_name, decoder_name) do
    %{property_name: property_name,
      decoder_name: decoder_name}
  end

  @spec print_encoder(
    Types.typeDefinition,
    SchemaDefinition.t,
    Types.schemaDictionary
  ) :: String.t
  def print_encoder(%AllOfType{name: name,
                               path: _path,
                               types: type_paths},
    schema_def, schema_dict) do

    type_name = upcase_first name
    encoder_name = "encode#{type_name}"
    argument_name = downcase_first type_name

    properties = create_encoder_properties(type_paths, schema_def, schema_dict)

    template = encoder_template(encoder_name, type_name,
      argument_name, properties)
    trim_newlines(template)
  end

  defp create_encoder_properties(type_paths, schema_def, schema_dict) do

    type_paths
    |> Enum.map(fn type_path ->
      Printer.resolve_type!(type_path, schema_def, schema_dict)
    end)
    |> Enum.reduce([], fn ({resolved_property, resolved_schema}, properties) ->
      encoder_name = create_encoder_name(
      {resolved_property, resolved_schema}, schema_def)
      updated_property = Map.put(resolved_property, :encoder_name, encoder_name)
      properties ++ [updated_property]
    end)
  end

end
