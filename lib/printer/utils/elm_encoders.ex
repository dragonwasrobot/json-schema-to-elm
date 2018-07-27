defmodule JS2E.Printer.Utils.ElmEncoders do
  @moduledoc ~S"""
  Module containing common utility functions for outputting
  Elm encoder definitions.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.{ErrorUtil, PrinterError, Utils}
  alias Types.{PrimitiveType, SchemaDefinition}
  alias Utils.Naming

  @doc ~S"""
  Returns the encoder name given a JSON schema type definition.
  """
  @spec create_encoder_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_encoder_name({:error, error}, _schema, _name), do: {:error, error}

  def create_encoder_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    encoder_name_result =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_type_encoder(resolved_type.type)

        _ ->
          type_name = resolved_type.name |> Naming.normalize_identifier(:upcase)

          if type_name == "#" do
            if resolved_schema.title != nil do
              {:ok, "encode#{Naming.upcase_first(resolved_schema.title)}"}
            else
              {:ok, "encodeRoot"}
            end
          else
            {:ok, "encode#{Naming.upcase_first(type_name)}"}
          end
      end

    case encoder_name_result do
      {:ok, encoder_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, Naming.qualify_name(resolved_schema, encoder_name, module_name)}
        else
          {:ok, encoder_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  "boolean", and "null" into their Elm encoder equivalent. Raises an error
  otherwise.

  ## Examples

  iex> determine_primitive_type_encoder("string")
  {:ok, "Encode.string"}

  iex> determine_primitive_type_encoder("integer")
  {:ok, "Encode.int"}

  iex> determine_primitive_type_encoder("number")
  {:ok, "Encode.float"}

  iex> determine_primitive_type_encoder("boolean")
  {:ok, "Encode.bool"}

  iex> determine_primitive_type_encoder("null")
  {:ok, "Encode.null"}

  iex> {:error, error} = determine_primitive_type_encoder("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type_encoder(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type_encoder(type_name) do
    case type_name do
      "string" ->
        {:ok, "Encode.string"}

      "integer" ->
        {:ok, "Encode.int"}

      "number" ->
        {:ok, "Encode.float"}

      "boolean" ->
        {:ok, "Encode.bool"}

      "null" ->
        {:ok, "Encode.null"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end
end
