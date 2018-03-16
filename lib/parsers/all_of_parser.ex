defmodule JS2E.Parsers.AllOfParser do
  @behaviour JS2E.Parsers.ParserBehaviour
  @moduledoc ~S"""
  Parses a JSON schema allOf type:

      {
        "allOf": [
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

  Into an `JS2E.Types.AllOfType`.
  """

  require Logger

  import JS2E.Parsers.Util,
    only: [
      parse_child_types: 3,
      create_types_list: 2,
      create_type_dict: 3
    ]

  alias JS2E.Parsers.{ErrorUtil, ParserResult}
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.AllOfType

  @doc ~S"""
  Returns true if the JSON subschema represents an allOf type.

  ## Examples

  iex> type?(%{})
  false

  iex> type?(%{"allOf" => []})
  false

  iex> type?(%{"allOf" => [%{"$ref" => "#foo"}]})
  true

  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec type?(Types.node()) :: boolean
  def type?(%{"allOf" => all_of})
      when is_list(all_of) and length(all_of) > 0,
      do: true

  def type?(_schema_node), do: false

  @doc ~S"""
  Parses a JSON schema allOf type into an `JS2E.Types.AllOfType`.
  """
  @impl JS2E.Parsers.ParserBehaviour
  @spec parse(Types.node(), URI.t(), URI.t() | nil, TypePath.t(), String.t()) :: ParserResult.t()
  def parse(%{"allOf" => all_of}, parent_id, id, path, name)
      when is_list(all_of) do
    child_path = TypePath.add_child(path, "allOf")

    child_types_result =
      all_of
      |> parse_child_types(parent_id, child_path)

    all_of_types =
      child_types_result.type_dict
      |> create_types_list(child_path)

    all_of_type = AllOfType.new(name, path, all_of_types)

    all_of_type
    |> create_type_dict(path, id)
    |> ParserResult.new()
    |> ParserResult.merge(child_types_result)
  end
end
