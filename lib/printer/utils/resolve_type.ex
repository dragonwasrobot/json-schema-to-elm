defmodule JS2E.Printer.Utils.ResolveType do
  @moduledoc ~S"""
  Module containing functions for resolving types. Main function being
  the `resolve_type` function.
  """

  alias JS2E.{TypePath, Types}
  alias JS2E.Types.{PrimitiveType, TypeReference, SchemaDefinition}
  alias JS2E.Printer.{ErrorUtil, PrinterError}

  @spec resolve_type(
          Types.typeIdentifier(),
          Types.typeIdentifier(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  def resolve_type(identifier, parent, schema_def, schema_dict) do
    resolved_result =
      cond do
        identifier in ["string", "number", "integer", "boolean"] ->
          resolve_primitive_identifier(identifier, schema_def)

        TypePath.type_path?(identifier) ->
          resolve_type_path_identifier(identifier, parent, schema_def)

        URI.parse(identifier).scheme != nil ->
          resolve_uri_identifier(URI.parse(identifier), parent, schema_dict)

        true ->
          {:error, ErrorUtil.unresolved_reference(identifier, parent)}
      end

    case resolved_result do
      {:ok, {resolved_type, resolved_schema_def}} ->
        case resolved_type do
          %TypeReference{} ->
            resolve_type(
              resolved_type.path,
              parent,
              resolved_schema_def,
              schema_dict
            )

          _ ->
            {:ok, {resolved_type, resolved_schema_def}}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec resolve_primitive_identifier(String.t(), SchemaDefinition.t()) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
  defp resolve_primitive_identifier(identifier, schema_def) do
    primitive_type = PrimitiveType.new(identifier, identifier, identifier)
    {:ok, {primitive_type, schema_def}}
  end

  @spec resolve_type_path_identifier(
          TypePath.t(),
          TypePath.t(),
          SchemaDefinition.t()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  defp resolve_type_path_identifier(identifier, parent, schema_def) do
    type_dict = schema_def.types
    resolved_type = type_dict[TypePath.to_string(identifier)]

    if resolved_type != nil do
      {:ok, {resolved_type, schema_def}}
    else
      {:error, ErrorUtil.unresolved_reference(identifier, parent)}
    end
  end

  @spec resolve_uri_identifier(
          URI.t(),
          Types.typeIdentifier(),
          Types.schemaDictionary()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  defp resolve_uri_identifier(identifier, parent, schema_dict) do
    schema_id = determine_schema_id(identifier)
    schema_def = schema_dict[schema_id]

    if schema_def != nil do
      type_dict = schema_def.types

      resolved_type =
        if to_string(identifier) == schema_id do
          type_dict["#"]
        else
          type_dict[to_string(identifier)]
        end

      if resolved_type != nil do
        {:ok, {resolved_type, schema_def}}
      else
        {:error, ErrorUtil.unresolved_reference(identifier, parent)}
      end
    else
      {:error, ErrorUtil.unresolved_reference(identifier, parent)}
    end
  end

  @spec determine_schema_id(URI.t()) :: String.t()
  defp determine_schema_id(identifier) do
    identifier
    |> Map.put(:fragment, nil)
    |> to_string
  end
end
