defmodule JS2E.Printer.Utils.ElmEncoders do
  @moduledoc """
  Module containing common utility functions for outputting
  Elm encoder definitions.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.{PrinterError, Utils}
  alias Types.{PrimitiveType, SchemaDefinition}
  alias Utils.Naming

  @type encoder_definition ::
          {:product, product_encoder}
          | {:tuple, tuple_encoder}
          | {:sum, sum_encoder}
          | {:enum, enum_encoder}
          | {:list, list_encoder}

  @type product_encoder :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          properties: [product_property]
        }

  @type product_property :: %{
          required: boolean,
          name: String.t(),
          location: String.t(),
          encoder_name: String.t()
        }

  @type tuple_encoder :: %{
          name: String.t(),
          type: String.t(),
          properties: [%{name: String.t(), encoder_name: String.t()}]
        }

  @type sum_encoder :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          cases: %{constructor: String.t(), encoder: String.t()}
        }

  @type enum_encoder :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          argument_js_type: String.t(),
          clauses: [%{elm_value: String.t(), json_value: String.t()}]
        }

  @type list_encoder :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          items_encoder: String.t()
        }

  @doc """
  Returns the encoder name given a JSON schema type definition.
  """
  @spec create_encoder_property(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          String.t(),
          [String.t()],
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, product_property()} | {:error, PrinterError.t()}
  def create_encoder_property(
        resolved_type,
        resolved_schema,
        property_name,
        required,
        context_schema,
        module_name
      ) do
    encoder_name =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_type_encoder(resolved_type.type)

        _ ->
          type_name = resolved_type.name |> Naming.normalize_identifier(:upcase)

          if type_name == "#" do
            if resolved_schema.title != nil do
              "encode#{Naming.upcase_first(resolved_schema.title)}"
            else
              "encodeRoot"
            end
          else
            "encode#{Naming.upcase_first(type_name)}"
          end
      end

    if resolved_schema.id != context_schema.id do
      {:ok,
       %{
         name: Naming.normalize_identifier(property_name, :downcase),
         location: Naming.normalize_identifier(property_name, :downcase),
         encoder_name: Naming.qualify_name(resolved_schema, encoder_name, module_name),
         required: property_name in required
       }}
    else
      {:ok,
       %{
         name: Naming.normalize_identifier(property_name, :downcase),
         location: Naming.normalize_identifier(property_name, :downcase),
         encoder_name: encoder_name,
         required: property_name in required
       }}
    end
  end

  @doc ~S"""
  Converts a primitive value type into the corresponding Elm encoder.

  ## Examples

      iex> determine_primitive_type_encoder(:string)
      "Encode.string"

      iex> determine_primitive_type_encoder(:integer)
      "Encode.int"

      iex> determine_primitive_type_encoder(:number)
      "Encode.float"

      iex> determine_primitive_type_encoder(:boolean)
      "Encode.bool"

      iex> determine_primitive_type_encoder(:null)
      "Encode.null"
  """
  @spec determine_primitive_type_encoder(PrimitiveType.value_type()) :: String.t()
  def determine_primitive_type_encoder(value_type) do
    case value_type do
      :string -> "Encode.string"
      :integer -> "Encode.int"
      :number -> "Encode.float"
      :boolean -> "Encode.bool"
      :null -> "Encode.null"
    end
  end
end
