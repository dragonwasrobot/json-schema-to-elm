defmodule JS2E.Parsers.OneOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema oneOf type:

      {
        "oneOf": [
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

  Into an `JS2E.Types.OneOfType`.
  """

  require Logger
  import JS2E.Parsers.Util, only: [
    parse_child_types: 3,
    create_type_dict: 3,
    create_types_list: 2
  ]
  alias JS2E.Parsers.{ErrorUtil, ParserResult}
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.OneOfType

  @doc ~S"""
  Returns true if the json subschema represents an oneOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"oneOf" => []})
  false

  iex> type?(%{"oneOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(Types.node) :: boolean
  def type?(schema_node) do
    one_of = schema_node["oneOf"]
    is_list(one_of) && length(one_of) > 0
  end

  @doc ~S"""
  Parses a JSON schema oneOf type into an `JS2E.Types.OneOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.node, URI.t, URI.t, TypePath.t, String.t)
  :: ParserResult.t
  def parse(%{"oneOf" => one_of}, parent_id, id, path, name)
  when is_list(one_of) do

    child_path = TypePath.add_child(path, "oneOf")

    child_types_result =
      one_of
      |> parse_child_types(parent_id, child_path)

    one_of_types =
      child_types_result.type_dict
      |> create_types_list(child_path)

    one_of_type = OneOfType.new(name, path, one_of_types)

    one_of_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(child_types_result)
  end

end
