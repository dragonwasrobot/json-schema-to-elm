defmodule JS2E.SchemaVersion do


  @supported_versions [
    "http://json-schema.org/draft-04/schema"
  ]

  @doc ~S"""
  Returns `:ok` if the given JSON schema has a known supported version,
  and an error tuple otherwise.

  ## Examples

      iex> schema = %{"$schema" => "http://json-schema.org/draft-04/schema"}
      iex> supported_schema_version?(schema)
      :ok

      iex> schema = %{"$schema" => "http://example.org/my-own-schema"}
      iex> schema |> supported_schema_version? |> elem(0)
      :error

      iex> supported_schema_version?(%{})
      {:error, "JSON Schema has no '$schema' keyword"}
  """
  @spec supported_schema_version?(map) :: :ok | {:error, String.t}
  def supported_schema_version?(%{"$schema" => schema_str}) do

    schema_identifier = schema_str |> URI.parse |> to_string
    if schema_identifier in @supported_versions do
      :ok

    else
      {:error, "Unsupported JSON schema version identifier " <>
        "found in '$schema': '#{schema_str}', " <>
        "supported versions are: #{inspect @supported_versions}"}
    end

  end
  def supported_schema_version?(_schema) do
    {:error, "JSON Schema has no '$schema' keyword"}
  end

end
