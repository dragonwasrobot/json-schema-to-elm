defmodule JS2E.Parser.TupleParser do
  @behaviour JS2E.Parser.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema array type:

      {
        "type": "array",
        "items": [
          { "$ref": "#/rectangle" },
          { "$ref": "#/circle" }
        ]
      }

  Into a `JS2E.Types.TupleType`.
  """

  require Logger

  alias JS2E.Parser.{Util, ErrorUtil, ParserResult}
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.TupleType

  @doc ~S"""
  Returns true if the json subschema represents a tuple type.

  ## Examples

  iex> type?(%{})
  false

  iex> aTuple = %{"items" => [%{"$ref" => "#foo"}, %{"$ref" => "#bar"}]}
  iex> type?(aTuple)
  true

  """
  @impl JS2E.Parser.ParserBehaviour
  @spec type?(Types.node()) :: boolean
  def type?(schema_node) do
    items = schema_node["items"]
    is_list(items)
  end

  @doc ~S"""
  Parses a JSON schema array type into an `JS2E.Types.TupleType`.
  """
  @impl JS2E.Parser.ParserBehaviour
  @spec parse(Types.node(), URI.t(), URI.t() | nil, TypePath.t(), String.t()) ::
          ParserResult.t()
  def parse(%{"items" => items}, parent_id, id, path, name)
      when is_list(items) do
    child_path = TypePath.add_child(path, "items")

    child_types_result =
      items
      |> Util.parse_child_types(parent_id, child_path)

    tuple_types =
      child_types_result.type_dict
      |> Util.create_types_list(child_path)

    tuple_type = TupleType.new(name, path, tuple_types)

    tuple_type
    |> Util.create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(child_types_result)
  end

  def parse(%{"items" => items}, _parent_id, _id, path, _name) do
    items_type = ErrorUtil.get_type(items)
    error = ErrorUtil.invalid_type(path, "items", "list or object", items_type)
    ParserResult.new(%{}, [], [error])
  end
end
