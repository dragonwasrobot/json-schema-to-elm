defmodule DecoderGenerator.Types do
  @moduledoc ~S"""
  Specifies the main Elixir types used for describing the
  intermediate representations of JSON schema types.
  """

  alias DecoderGenerator.Types.{ArrayType, EnumType, PrimitiveType,
                                ObjectType, OneOfType, UnionType,
                                TypeReference, SchemaDefinition}

  @type typeDefinition :: (
    ArrayType.t |
    EnumType.t |
    PrimitiveType.t |
    ObjectType.t |
    OneOfType.t |
    UnionType.t |
    TypeReference.t
  )

  @type typeDictionary :: %{required(String.t) => typeDefinition}
  @type schemaDictionary :: %{required(String.t) => SchemaDefinition.t}
  @type fileDictionary :: %{required(String.t) => String.t}

end
