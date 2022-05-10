defmodule JS2E.Printer.Utils.ElmFuzzers do
  @moduledoc """
  Module containing common utility functions for outputting Elm fuzzers and
  tests.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{PrinterError, Utils}

  alias Types.{
    AllOfType,
    ArrayType,
    ObjectType,
    PrimitiveType,
    SchemaDefinition
  }

  alias Utils.{CommonOperations, Naming}

  @type fuzzer_definition ::
          {:product, product_fuzzer}
          | {:tuple, tuple_fuzzer}
          | {:sum, sum_fuzzer}
          | {:list, list_fuzzer}

  @type product_fuzzer :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          decoder_name: String.t(),
          encoder_name: String.t(),
          field_fuzzers: [field_fuzzer]
        }

  @type tuple_fuzzer :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          decoder_name: String.t(),
          encoder_name: String.t(),
          field_fuzzers: [field_fuzzer]
        }

  @type field_fuzzer :: %{field_name: String.t(), fuzzer_name: String.t()}

  @type sum_fuzzer :: %{
          name: String.t(),
          type: String.t(),
          argument_name: String.t(),
          decoder_name: String.t(),
          encoder_name: String.t(),
          clause_fuzzers: [String.t()]
        }

  @type list_fuzzer :: %{
          name: String.t(),
          array_name: String.t(),
          items_type: String.t(),
          items_fuzzer: String.t(),
          argument_name: String.t(),
          decoder_name: String.t(),
          encoder_name: String.t()
        }

  @spec create_fuzzer_names(
          String.t(),
          Types.typeDefinition(),
          SchemaDefinition.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, [field_fuzzer]} | {:error, PrinterError.t()}
  def create_fuzzer_names(
        property_name,
        resolved_type,
        resolved_schema,
        context_schema,
        schema_dict,
        module_name
      ) do
    if resolved_type.name == :anonymous do
      {resolved_pairs, errors} =
        case resolved_type do
          %AllOfType{} ->
            resolved_type.types
            |> Enum.map(fn {_name, path} ->
              Resolver.resolve_type(
                path,
                resolved_type.path,
                context_schema,
                schema_dict
              )
            end)
            |> CommonOperations.split_ok_and_errors()

          %ArrayType{} ->
            {[], []}

          %ObjectType{} ->
            resolved_type.properties
            |> Enum.map(fn {_name, path} ->
              Resolver.resolve_type(
                path,
                resolved_type.path,
                context_schema,
                schema_dict
              )
            end)
            |> CommonOperations.split_ok_and_errors()

          _ ->
            # TODO: Other cases?
            {[], []}
        end

      if errors != [] do
        {:error, errors}
      else
        fuzzer_names =
          resolved_pairs
          |> Enum.map(fn {resolved_type, schema} ->
            do_create_fuzzer_name(
              resolved_type.name,
              resolved_type,
              schema,
              context_schema,
              module_name
            )
          end)

        {:ok, fuzzer_names}
      end
    else
      fuzzer_name =
        do_create_fuzzer_name(
          property_name,
          resolved_type,
          resolved_schema,
          context_schema,
          module_name
        )

      {:ok, [fuzzer_name]}
    end
  end

  @spec do_create_fuzzer_name(
          String.t(),
          Types.typeDefinition(),
          SchemaDefinition.t(),
          SchemaDefinition.t(),
          String.t()
        ) :: field_fuzzer
  defp do_create_fuzzer_name(
         property_name,
         resolved_type,
         resolved_schema,
         context_schema,
         module_name
       ) do
    fuzzer_name =
      case resolved_type do
        %PrimitiveType{} ->
          determine_primitive_fuzzer_name(resolved_type.type)

        _ ->
          downcased_type_name = Naming.normalize_identifier(resolved_type.name, :downcase)
          "#{downcased_type_name}Fuzzer"
      end

    if resolved_schema.id != context_schema.id do
      %{
        field_name: property_name,
        fuzzer_name: Naming.qualify_name(resolved_schema, fuzzer_name, module_name)
      }
    else
      %{field_name: property_name, fuzzer_name: fuzzer_name}
    end
  end

  @doc ~S"""
  Converts a primitive value type into the corresponding Elm fuzzer.

  ## Examples

      iex> determine_primitive_fuzzer_name(:string)
      "Fuzz.string"

      iex> determine_primitive_fuzzer_name(:integer)
      "Fuzz.int"

      iex> determine_primitive_fuzzer_name(:number)
      "Fuzz.float"

      iex> determine_primitive_fuzzer_name(:boolean)
      "Fuzz.bool"

  """
  @spec determine_primitive_fuzzer_name(PrimitiveType.value_type()) :: String.t()
  def determine_primitive_fuzzer_name(value_type) do
    case value_type do
      :string -> "Fuzz.string"
      :number -> "Fuzz.float"
      :integer -> "Fuzz.int"
      :boolean -> "Fuzz.bool"
      :null -> "Fuzzer.unit"
    end
  end
end
