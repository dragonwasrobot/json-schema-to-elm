defmodule JS2E.Printer.Utils.ElmDecoders do
  @moduledoc ~S"""
  Module containing common utility functions for outputting
  Elm decoder definitions.
  """

  require Logger
  alias JS2E.{Printer, Types}
  alias Printer.{ErrorUtil, PrinterError, Utils}
  alias Types.{PrimitiveType, SchemaDefinition}
  alias Utils.Naming

  @spec create_decoder_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_decoder_name({:error, error}, _schema, _name), do: {:error, error}

  def create_decoder_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    decoder_name =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_type_decoder(resolved_type.type)

        _ ->
          type_name =
            resolved_type.name |> Naming.normalize_identifier(:downcase)

          if type_name == "#" do
            if resolved_schema.title != nil do
              {:ok, "#{Naming.downcase_first(resolved_schema.title)}Decoder"}
            else
              {:ok, "rootDecoder"}
            end
          else
            {:ok, "#{type_name}Decoder"}
          end
      end

    case decoder_name do
      {:ok, decoder_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, Naming.qualify_name(resolved_schema, decoder_name, module_name)}
        else
          {:ok, decoder_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm decoder equivalent. Raises an error otherwise.

  ## Examples

  iex> determine_primitive_type_decoder("string")
  {:ok, "Decode.string"}

  iex> determine_primitive_type_decoder("integer")
  {:ok, "Decode.int"}

  iex> determine_primitive_type_decoder("number")
  {:ok, "Decode.float"}

  iex> determine_primitive_type_decoder("boolean")
  {:ok, "Decode.bool"}

  iex> {:error, error} = determine_primitive_type_decoder("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type_decoder(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type_decoder(type_name) do
    case type_name do
      "string" ->
        {:ok, "Decode.string"}

      "integer" ->
        {:ok, "Decode.int"}

      "number" ->
        {:ok, "Decode.float"}

      "boolean" ->
        {:ok, "Decode.bool"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end
end
