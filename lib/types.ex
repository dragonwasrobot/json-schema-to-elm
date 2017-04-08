defmodule JS2E.Types do
  @moduledoc ~S"""
  Specifies the main Elixir types used for describing the
  intermediate representations of JSON schema types.
  """

  alias JS2E.TypePath
  alias JS2E.Types.{ArrayType, EnumType, PrimitiveType, ObjectType,
                    AllOfType, AnyOfType, OneOfType, UnionType,
                    TypeReference, SchemaDefinition}

  @type typeDefinition :: (
    ArrayType.t |
    EnumType.t |
    PrimitiveType.t |
    ObjectType.t |
    AllOfType.t |
    AnyOfType.t |
    OneOfType.t |
    UnionType.t |
    TypeReference.t
  )

  @type typeIdentifier :: (TypePath.t | URI.t | String.t)
  @type propertyDictionary :: %{required(String.t) => typeIdentifier}
  @type typeDictionary :: %{required(String.t) => typeDefinition}
  @type schemaDictionary :: %{required(String.t) => SchemaDefinition.t}
  @type fileDictionary :: %{required(String.t) => String.t}

end
