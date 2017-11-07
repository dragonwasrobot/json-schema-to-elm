defmodule JS2E.Types do
  @moduledoc ~S"""
  Specifies the main Elixir types used for describing the
  intermediate representations of JSON schema types.
  """

  alias JS2E.TypePath
  alias JS2E.Printers.PrinterResult
  alias JS2E.Types.{AllOfType, AnyOfType, ArrayType, EnumType,
                    ObjectType, OneOfType, PrimitiveType, SchemaDefinition,
                    TupleType, TypeReference, UnionType}

  @type typeDefinition :: (
    AllOfType.t |
    AnyOfType.t |
    ArrayType.t |
    EnumType.t |
    ObjectType.t |
    OneOfType.t |
    PrimitiveType.t |
    TupleType.t |
    TypeReference.t |
    UnionType.t
  )

  @type schemaNode :: map
  @type typeIdentifier :: (String.t | TypePath.t | URI.t)
  @type propertyDictionary :: %{required(String.t) => typeIdentifier}
  @type typeDictionary :: %{required(String.t) => typeDefinition}
  @type schemaDictionary :: %{required(String.t) => SchemaDefinition.t}
  @type fileDictionary :: %{required(String.t) => String.t}

end
