defmodule JS2E.Types.PrimitiveType do
  @moduledoc ~S"""
  Represents a custom 'primitive' type definition in a JSON schema.

  Limitations:

  While the standard states:

      String values MUST be one of the seven primitive types defined by the core
      specification.

  We currently restrict the types to "string", "null", "boolean", "number" and
  "integer" when it comes to parsing schemas as primitive types.

  However, we currently require "type" to be equal to "object" or "array" when
  parsing a schema as an object or an array type, and we likewise require that
  the "properties" or "items" property is present.

  JSON Schema:

      "name": {
          "type": "string"
      }

  Elixir intermediate representation:

      %PrimitiveType{name: "name",
                     path: "#/name",
                     type: "string"}

  Elm code generated:

  - Usage

      |> required "name" string
  """

  @type t :: %__MODULE__{name: String.t,
                         path: String.t,
                         type: String.t}

  defstruct [:name, :path, :type, :default]
end
