defmodule JS2E.Predicates do
  @moduledoc ~S"""
  Contains various predicate functions for working with json schemas.
  """

  @doc ~S"""
  Returns true if the json schema contains a 'definitions' property.

  ## Examples

      iex> JS2E.Predicates.definitions?(%{"title" => "A fancy title"})
      false

      iex> JS2E.Predicates.definitions?(%{"definitions" => %{}})
      true

  """
  @spec definitions?(map) :: boolean
  def definitions?(schema_node) do
    Map.has_key?(schema_node, "definitions")
  end

  @doc ~S"""
  Returns true if the json subschema represents a primitive type.

  ## Examples

      iex> JS2E.Predicates.primitive_type?(%{})
      false

      iex> JS2E.Predicates.primitive_type?(%{"type" => "object"})
      false

      iex> JS2E.Predicates.primitive_type?(%{"type" => "boolean"})
      true

      iex> JS2E.Predicates.primitive_type?(%{"type" => "integer"})
      true

  """
  @spec primitive_type?(map) :: boolean
  def primitive_type?(schema_node) do
    schema_node["type"] in ["null", "boolean", "string", "number", "integer"]
  end

  @doc ~S"""
  Returns true if the json subschema represents a reference to another schema.

  ## Examples

      iex> JS2E.Predicates.ref_type?(%{})
      false

      iex> JS2E.Predicates.ref_type?(%{"$ref" => "#foo"})
      true

  """
  @spec ref_type?(map) :: boolean
  def ref_type?(schema_node) do
    Map.has_key?(schema_node, "$ref")
  end

  @doc ~S"""
  Returns true if the json subschema represents an enum type.

  ## Examples

  iex> JS2E.Predicates.enum_type?(%{})
  false

  iex> JS2E.Predicates.enum_type?(%{"enum" => ["red", "yellow", "green"]})
  true

  """
  @spec enum_type?(map) :: boolean
  def enum_type?(schema_node) do
    Map.has_key?(schema_node, "enum")
  end

  @doc ~S"""
  Returns true if the json subschema represents an allOf type.

  ## Examples

  iex> JS2E.Predicates.all_of_type?(%{})
  false

  iex> JS2E.Predicates.all_of_type?(%{"allOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @spec all_of_type?(map) :: boolean
  def all_of_type?(schema_node) do
    Map.has_key?(schema_node, "allOf")
  end

  @doc ~S"""
  Returns true if the json subschema represents an anyOf type.

  ## Examples

  iex> JS2E.Predicates.any_of_type?(%{})
  false

  iex> JS2E.Predicates.any_of_type?(%{"anyOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @spec any_of_type?(map) :: boolean
  def any_of_type?(schema_node) do
    Map.has_key?(schema_node, "anyOf")
  end

  @doc ~S"""
  Returns true if the json subschema represents an oneOf type.

  ## Examples

  iex> JS2E.Predicates.one_of_type?(%{})
  false

  iex> JS2E.Predicates.one_of_type?(%{"oneOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @spec one_of_type?(map) :: boolean
  def one_of_type?(schema_node) do
    Map.has_key?(schema_node, "oneOf")
  end

  @doc ~S"""
  Returns true if the json subschema represents a union type.

  ## Examples

  iex> JS2E.Predicates.union_type?(%{})
  false

  iex> JS2E.Predicates.union_type?(%{"type" => ["number", "integer", "string"]})
  true

  """
  @spec union_type?(map) :: boolean
  def union_type?(schema_node) do
    is_list(schema_node["type"])
  end

  @doc ~S"""
  Returns true if the json subschema represents an allOf type.

  ## Examples

  iex> JS2E.Predicates.object_type?(%{})
  false

  iex> JS2E.Predicates.object_type?(%{"type" => "object"})
  false

  iex> anObject = %{"type" => "object",
  ...>              "properties" => %{"name" => %{"type" => "string"}}}
  iex> JS2E.Predicates.object_type?(anObject)
  true

  """
  @spec object_type?(map) :: boolean
  def object_type?(schema_node) do
    schema_node["type"] == "object" && Map.has_key?(schema_node, "properties")
  end

  @doc ~S"""
  Returns true if the json subschema represents an array type.

  ## Examples

  iex> JS2E.Predicates.array_type?(%{})
  false

  iex> JS2E.Predicates.array_type?(%{"type" => "array"})
  false

  iex> anArray = %{"type" => "array", "items" => %{"$ref" => "#foo"}}
  iex> JS2E.Predicates.array_type?(anArray)
  true

  """
  @spec array_type?(map) :: boolean
  def array_type?(schema_node) do
    schema_node["type"] == "array" && Map.has_key?(schema_node, "items")
  end

end
