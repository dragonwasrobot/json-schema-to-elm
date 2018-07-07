defmodule JS2E.Printer.Utils.ElmFuzzers do
  @moduledoc ~S"""
  Module containing common utility functions for outputting Elm fuzzers and
  tests.
  """

  require Logger
  alias JS2E.{Printer, Types}
  alias Printer.{ErrorUtil, PrinterError, Utils}
  alias Types.{PrimitiveType, SchemaDefinition}
  alias Utils.Naming

  @spec create_fuzzer_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_fuzzer_name({:error, error}, _schema, _name), do: {:error, error}

  def create_fuzzer_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    fuzzer_name_result =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_fuzzer_name(resolved_type.type)

        _ ->
          resolved_type_name = resolved_type.name

          downcased_type_name =
            Naming.normalize_identifier(resolved_type_name, :downcase)

          {:ok, "#{downcased_type_name}Fuzzer"}
      end

    case fuzzer_name_result do
      {:ok, fuzzer_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, Naming.qualify_name(resolved_schema, fuzzer_name, module_name)}
        else
          {:ok, fuzzer_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm type equivalent. Raises and error otherwise.

  ## Examples

  iex> determine_primitive_fuzzer_name("string")
  {:ok, "Fuzz.string"}

  iex> determine_primitive_fuzzer_name("integer")
  {:ok, "Fuzz.int"}

  iex> determine_primitive_fuzzer_name("number")
  {:ok, "Fuzz.float"}

  iex> determine_primitive_fuzzer_name("boolean")
  {:ok, "Fuzz.bool"}

  iex> {:error, error} = determine_primitive_fuzzer_name("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_fuzzer_name(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_fuzzer_name(type_name) do
    case type_name do
      "string" ->
        {:ok, "Fuzz.string"}

      "integer" ->
        {:ok, "Fuzz.int"}

      "number" ->
        {:ok, "Fuzz.float"}

      "boolean" ->
        {:ok, "Fuzz.bool"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end
end
