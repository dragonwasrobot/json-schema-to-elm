defmodule JS2E.Printer.Utils.ElmTypes do
  @moduledoc ~S"""
  Module containing common utility functions for outputting Elm `type`
  and `type alias` definitions.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{ErrorUtil, PrinterError, Utils}
  alias Types.{ArrayType, PrimitiveType, SchemaDefinition}
  alias Utils.Naming

  @spec create_type_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_type_name({:error, error}, _parent, _schema, _schema_dict, _name),
    do: {:error, error}

  def create_type_name(
        {:ok, {resolved_type, resolved_schema}},
        parent,
        context_schema,
        schema_dict,
        module_name
      ) do
    type_name =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_type_name(resolved_type.type)

        %ArrayType{} ->
          case Resolver.resolve_type(
                 resolved_type.items,
                 parent,
                 context_schema,
                 schema_dict
               ) do
            {:ok, {items_type, _items_schema}} ->
              case items_type do
                %PrimitiveType{} ->
                  case determine_primitive_type_name(items_type.type) do
                    {:ok, primitive_type} ->
                      {:ok, "List #{primitive_type}"}

                    {:error, error} ->
                      {:error, error}
                  end

                _ ->
                  {:ok, "List #{Naming.upcase_first(items_type.name)}"}
              end

            {:error, error} ->
              {:error, error}
          end

        _ ->
          {:ok, Naming.upcase_first(resolved_type.name)}
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
