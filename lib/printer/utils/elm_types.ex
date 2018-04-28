defmodule JS2E.Printer.Utils.ElmTypes do
  @moduledoc ~S"""
  Module containing common utility functions for outputting Elm `type`
  and `type alias` definitions.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Types.{PrimitiveType, SchemaDefinition}
  alias JS2E.Printer.Utils.Naming
  alias JS2E.Printer.{ErrorUtil, PrinterError}

  @spec create_type_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_type_name({:error, error}, _schema, _name), do: {:error, error}

  def create_type_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    type_name =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_type_name(resolved_type.type)

        _ ->
          resolved_type_name = resolved_type.name
          {:ok, Naming.upcase_first(resolved_type_name)}
      end

    case type_name do
      {:ok, type_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, Naming.qualify_name(resolved_schema, type_name, module_name)}
        else
          {:ok, type_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm type equivalent. Raises and error otherwise.

  ## Examples

  iex> determine_primitive_type_name("string")
  {:ok, "String"}

  iex> determine_primitive_type_name("integer")
  {:ok, "Int"}

  iex> determine_primitive_type_name("number")
  {:ok, "Float"}

  iex> determine_primitive_type_name("boolean")
  {:ok, "Bool"}

  iex> {:error, error} = determine_primitive_type_name("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type_name(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type_name(type_name) do
    case type_name do
      "string" ->
        {:ok, "String"}

      "integer" ->
        {:ok, "Int"}

      "number" ->
        {:ok, "Float"}

      "boolean" ->
        {:ok, "Bool"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end
end
