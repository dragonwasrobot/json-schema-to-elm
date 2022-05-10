defmodule JS2E.Printer.Utils.ElmTypes do
  @moduledoc """
  Module containing common utility functions for outputting Elm `type`
  and `type alias` definitions.
  """

  require Logger
  alias JS2E.Printer
  alias JsonSchema.{Resolver, Types}
  alias Printer.{PrinterError, Utils}
  alias Types.{ArrayType, ObjectType, PrimitiveType, SchemaDefinition}
  alias Utils.{CommonOperations, Naming}

  @type type_definition :: {:product, product_type} | {:sum, sum_type}

  @type product_type :: %{
          name: String.t(),
          fields: {:named, [named_field]} | {:anonymous, [anonymous_field]}
        }
  @type anonymous_field :: %{type: String.t()}
  @type named_field :: %{name: String.t(), type: String.t()}

  @type sum_type :: %{
          name: String.t(),
          clauses: {:named, [named_clause]} | {:anonymous, [anonymous_clause]}
        }
  @type anonymous_clause :: %{type: String.t()}
  @type named_clause :: %{name: String.t(), type: String.t()}

  @spec create_fields(
          String.t() | :anonymous,
          Types.typeDefinition(),
          SchemaDefinition.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) ::
          {:ok, [named_field()]}
          | {:error, PrinterError.t()}
  def create_fields(
        property_name,
        resolved_type,
        resolved_schema,
        parent,
        context_schema,
        schema_dict,
        module_name
      ) do
    if resolved_type.name == :anonymous do
      do_create_fields(
        resolved_type,
        resolved_schema,
        parent,
        context_schema,
        schema_dict
      )
    else
      do_create_field(
        property_name,
        resolved_type,
        resolved_schema,
        parent,
        context_schema,
        schema_dict,
        module_name
      )
    end
  end

  @spec do_create_fields(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) ::
          {:ok, [named_field]} | {:error, PrinterError.t()}
  def do_create_fields(
        resolved_type,
        _resolved_schema,
        _parent,
        context_schema,
        schema_dict
      ) do
    case resolved_type do
      %ObjectType{} ->
        {type_names, errors} =
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
                    primitive_type = determine_primitive_type_name(property_type.type)
                    {:ok, %{name: name, type: primitive_type}}

                  _ ->
                    {:ok,
                     %{
                       name: name,
                       type: Naming.upcase_first(property_type.name)
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
          {:ok, type_names}
        end

      _ ->
        # TODO: Other types
        {:ok, []}
    end
  end

  @spec do_create_field(
          String.t() | :anonymous,
          Types.typeDefinition(),
          SchemaDefinition.t(),
          URI.t(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, named_field} | {:error, PrinterError.t()}
  def do_create_field(
        property_name,
        resolved_type,
        resolved_schema,
        parent,
        context_schema,
        schema_dict,
        module_name
      ) do
    case resolved_type do
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
                primitive_type = determine_primitive_type_name(items_type.type)

                {:ok,
                 [
                   %{
                     name: property_name,
                     type: "List #{primitive_type}"
                   }
                 ]}

              _ ->
                type_name = "List #{Naming.upcase_first(items_type.name)}"

                field =
                  check_qualified_name(
                    property_name,
                    type_name,
                    resolved_schema,
                    context_schema,
                    module_name
                  )

                {:ok, [field]}
            end

          {:error, error} ->
            {:error, error}
        end

      %PrimitiveType{} ->
        primitive_type = determine_primitive_type_name(resolved_type.type)
        {:ok, [%{name: property_name, type: primitive_type}]}

      _ ->
        type_name = Naming.upcase_first(resolved_type.name)

        field =
          check_qualified_name(
            property_name,
            type_name,
            resolved_schema,
            context_schema,
            module_name
          )

        {:ok, [field]}
    end
  end

  @spec check_qualified_name(
          String.t(),
          String.t(),
          SchemaDefinition.t(),
          SchemaDefinition.t(),
          String.t()
        ) :: named_field
  defp check_qualified_name(
         property_name,
         type_name,
         resolved_schema,
         context_schema,
         module_name
       ) do
    if resolved_schema.id != context_schema.id do
      field_name =
        if property_name != :anonymous do
          property_name |> Naming.downcase_first()
        else
          type_name |> Naming.downcase_first()
        end

      qualified_type_name = Naming.qualify_name(resolved_schema, type_name, module_name)
      field_type_name = qualified_type_name |> Naming.upcase_first()
      %{name: field_name, type: field_type_name}
    else
      field_name =
        if property_name != :anonymous do
          property_name |> Naming.downcase_first()
        else
          type_name |> Naming.downcase_first()
        end

      field_type_name = type_name |> Naming.upcase_first()
      %{name: field_name, type: field_type_name}
    end
  end

  @doc ~S"""
  Converts a primitive value type into the corresponding Elm type.

  ## Examples

      iex> determine_primitive_type_name(:string)
      "String"

      iex> determine_primitive_type_name(:integer)
      "Int"

      iex> determine_primitive_type_name(:number)
      "Float"

      iex> determine_primitive_type_name(:boolean)
      "Bool"
  """
  @spec determine_primitive_type_name(PrimitiveType.value_type()) :: String.t()
  def determine_primitive_type_name(value_type) do
    case value_type do
      :string -> "String"
      :integer -> "Int"
      :number -> "Float"
      :boolean -> "Bool"
      :null -> "()"
    end
  end
end
