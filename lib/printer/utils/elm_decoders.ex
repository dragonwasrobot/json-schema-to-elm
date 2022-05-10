defmodule JS2E.Printer.Utils.ElmDecoders do
  @moduledoc ~S"""
  Module containing common utility functions for outputting
  Elm decoder definitions.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{PrinterError, Utils}
  alias Types.{ObjectType, PrimitiveType, SchemaDefinition}
  alias Utils.{CommonOperations, Naming}

  @type decoder_definition ::
          {:product, product_decoder}
          | {:sum, sum_decoder}
          | {:enum, enum_decoder}
          | {:list, list_decoder}

  @type product_decoder ::
          %{
            name: String.t(),
            type: String.t(),
            clauses:
              {:anonymous, [anonymous_product_clause]}
              | {:named, [named_product_clause]}
          }

  @type anonymous_product_clause :: %{decoder_name: String.t()}
  @type named_product_clause :: %{
          option: option,
          property_name: String.t(),
          decoder_name: String.t()
        }

  @type option :: :required | :optional | :custom

  @type sum_decoder :: %{
          name: String.t(),
          type: String.t(),
          optional: boolean,
          clauses: {:anonymous, [anonymous_sum_clause]} | {:named, [named_sum_clause]}
        }

  @type anonymous_sum_clause :: %{decoder_name: String.t()}
  @type named_sum_clause :: %{
          decoder_name: String.t(),
          constructor_name: String.t()
        }

  @type enum_decoder :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          argument_type: String.t(),
          parser_name: String.t(),
          cases: [%{raw_value: String.t(), parsed_value: String.t()}]
        }

  @type list_decoder :: %{
          name: String.t(),
          type: String.t(),
          item_decoder: String.t()
        }

  @spec create_clauses(
          String.t() | :anonymous,
          Types.typeDefinition(),
          SchemaDefinition.t(),
          [String.t()],
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [named_product_clause()]} | {:error, PrinterError.t()}
  def create_clauses(
        property_name,
        resolved_type,
        resolved_schema,
        required,
        context_schema,
        schema_dict,
        module_name
      ) do
    if resolved_type.name == :anonymous do
      do_create_clauses(
        resolved_type,
        resolved_schema,
        required,
        context_schema,
        schema_dict,
        module_name
      )
    else
      do_create_clause(
        property_name,
        resolved_type,
        resolved_schema,
        required,
        context_schema,
        schema_dict,
        module_name
      )
    end
  end

  @spec do_create_clauses(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          [String.t()],
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [named_product_clause()]} | {:error, PrinterError.t()}
  def do_create_clauses(
        resolved_type,
        _resolved_schema,
        _required,
        context_schema,
        schema_dict,
        _module_name
      ) do
    case resolved_type do
      %ObjectType{} ->
        {decoder_names, errors} =
          resolved_type.properties
          |> Enum.map(fn {name, path} ->
            case Resolver.resolve_type(
                   path,
                   resolved_type.path,
                   context_schema,
                   schema_dict
                 ) do
              {:ok, {property_type, _property_schema}} ->
                case property_type do
                  %PrimitiveType{} ->
                    decoder_name = determine_primitive_type_decoder(property_type.type)

                    {:ok,
                     %{
                       option: :required,
                       property_name: name,
                       decoder_name: "#{decoder_name}"
                     }}

                  _ ->
                    {:ok,
                     %{
                       option: :required,
                       property_name: name,
                       decoder_name: "#{Naming.downcase_first(property_type.name)}Decoder"
                     }}
                end

              {:error, error} ->
                {:error, error}
            end
          end)
          |> CommonOperations.split_ok_and_errors()

        if errors != [] do
          {:error, errors}
        else
          {:ok, decoder_names}
        end

      _ ->
        {:ok, []}
    end
  end

  @spec do_create_clause(
          String.t() | :anonymous,
          Types.typeDefinition(),
          SchemaDefinition.t(),
          [String.t()],
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [named_product_clause()]} | {:error, PrinterError.t()}
  def do_create_clause(
        maybe_property_name,
        resolved_type,
        resolved_schema,
        required,
        context_schema,
        _schema_dict,
        module_name
      ) do
    property_name =
      if maybe_property_name != :anonymous do
        maybe_property_name
      else
        resolved_type.name
      end

    option =
      if property_name in required do
        :required
      else
        :optional
      end

    case resolved_type do
      %PrimitiveType{} ->
        decoder_name = determine_primitive_type_decoder(resolved_type.type)

        {:ok,
         [
           %{
             option: option,
             property_name: property_name,
             decoder_name: decoder_name
           }
         ]}

      _ ->
        type_name = resolved_type.name |> Naming.normalize_identifier(:downcase)

        decoder_name =
          if type_name == "#" do
            if resolved_schema.title != nil do
              "#{Naming.downcase_first(resolved_schema.title)}Decoder"
            else
              "rootDecoder"
            end
          else
            "#{type_name}Decoder"
          end

        decoder_name =
          decoder_name
          |> check_qualified_name(
            resolved_schema,
            context_schema,
            module_name
          )

        {:ok,
         [
           %{
             option: option,
             property_name: property_name,
             decoder_name: decoder_name
           }
         ]}
    end
  end

  @spec check_qualified_name(String.t(), SchemaDefinition.t(), SchemaDefinition.t(), String.t()) ::
          String.t()
  defp check_qualified_name(decoder_name, resolved_schema, context_schema, module_name) do
    if resolved_schema.id != context_schema.id do
      Naming.qualify_name(
        resolved_schema,
        decoder_name,
        module_name
      )
    else
      decoder_name
    end
  end

  @doc ~S"""
  Converts a primitive value type into the corresponding Elm decoder.

  ## Examples

      iex> determine_primitive_type_decoder(:string)
      "Decode.string"

      iex> determine_primitive_type_decoder(:integer)
      "Decode.int"

      iex> determine_primitive_type_decoder(:number)
      "Decode.float"

      iex> determine_primitive_type_decoder(:boolean)
      "Decode.bool"
  """
  @spec determine_primitive_type_decoder(PrimitiveType.value_type()) :: String.t()
  def determine_primitive_type_decoder(value_type) do
    case value_type do
      :string -> "Decode.string"
      :integer -> "Decode.int"
      :number -> "Decode.float"
      :boolean -> "Decode.bool"
      :null -> "(Decode.null ())"
    end
  end
end
