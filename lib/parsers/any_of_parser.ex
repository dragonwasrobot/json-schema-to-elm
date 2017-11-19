defmodule JS2E.Parsers.AnyOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema anyOf type:

      {
        "anyOf": [
          {
            "type": "object",
            "properties": {
              "color": {
                "$ref": "#/color"
              },
              "title": {
                "type": "string"
              },
              "radius": {
                "type": "number"
              }
            },
            "required": [ "color", "radius" ]
          },
          {
            "type": "string"
          }
        ]
      }

  Into an `JS2E.Types.AnyOfType`.
  """

  require Logger
  import JS2E.Parsers.Util, only: [
    parse_child_types: 3,
    create_types_list: 2,
    create_type_dict: 3
  ]
  alias JS2E.Parsers.{ErrorUtil, ParserResult}
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.AnyOfType

  @doc ~S"""
  Returns true if the json subschema represents an anyOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"anyOf" => []})
  false

  iex> type?(%{"anyOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(Types.schemaNode) :: boolean
  def type?(schema_node) do
    any_of = schema_node["anyOf"]
    is_list(any_of) && length(any_of) > 0
  end

  @doc ~S"""
  Parses a JSON schema anyOf type into an `JS2E.Types.AnyOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.schemaNode, URI.t, URI.t | nil, TypePath.t, String.t)
  :: ParserResult.t
  def parse(%{"anyOf" => any_of}, parent_id, id, path, name)
  when is_list(any_of) do

    child_path = TypePath.add_child(path, "anyOf")

    child_types_result =
      any_of
      |> parse_child_types(parent_id, child_path)

    any_of_types =
      child_types_result.type_dict
      |> create_types_list(child_path)

    any_of_type = AnyOfType.new(name, path, any_of_types)

    any_of_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(child_types_result)
  end

end
