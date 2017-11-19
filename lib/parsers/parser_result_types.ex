defmodule JS2E.Parsers.ParserError do
  @moduledoc ~S"""
  Represents an error generated while parsing a JSON schema object.
  """

  alias JS2E.Types

  @type t :: %__MODULE__{identifier: Types.typeIdentifier,
                         error_type: atom,
                         message: String.t}

  defstruct [:identifier, :error_type, :message]

  @doc ~S"""
  Constructs a `ParserError`.
  """
  @spec new(Types.typeIdentifier, atom, String.t) :: t
  def new(identifier, error_type, message) do
    %__MODULE__{identifier: identifier,
                error_type: error_type,
                message: message}
  end

  @doc ~S"""
  Pretty prints a `ParserError`.
  """
  @spec print(t, Path.t) :: String.t
  def print(%__MODULE__{identifier: identifier,
                        error_type: error_type,
                        message: message}, file_path) do
    "('#{file_path}#{identifier}'): #{message}"
  end
end

defmodule JS2E.Parsers.ParserWarning do
  @moduledoc ~S"""
  Represents a warning generated while parsing a JSON schema object.
  """

  alias JS2E.Types

  @type t :: %__MODULE__{identifier: Types.typeIdentifier,
                         warning_type: atom,
                         message: String.t}

  defstruct [:identifier, :warning_type, :message]

  @doc ~S"""
  Constructs a `ParserWarning`.
  """
  @spec new(Types.typeIdentifier, atom, String.t) :: t
  def new(identifier, warning_type, message) do
    %__MODULE__{identifier: identifier,
                warning_type: warning_type,
                message: message}
  end

  @doc ~S"""
  Pretty prints a `ParserWarning`.
  """
  @spec print(t, Path.t) :: String.t
  def print(%__MODULE__{identifier: identifier,
                        warning_type: warning_type,
                        message: message}, file_path) do
    "('#{file_path}#{identifier}'): #{message}"
  end
end

defmodule JS2E.Parsers.ParserResult do
  @moduledoc ~S"""
  Represents the result of parsing a subset of a JSON schema including
  parsed types, warnings, and errors.
  """

  require Logger
  alias JS2E.Types
  alias JS2E.Parsers.{ErrorUtil, ParserError, ParserWarning}

  @type t :: %__MODULE__{type_dict: Types.typeDictionary,
                         warnings: [ParserWarning.t],
                         errors: [ParserError.t]}

  defstruct [:type_dict, :warnings, :errors]

  @doc ~S"""
  Returns an empty `ParserResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{type_dict: %{}, warnings: [], errors: []}

  @doc ~S"""
  Creates a `ParserResult` from a type dictionary.

  A `ParserResult` consists of a type dictionary corresponding to the
  succesfully parsed part of a JSON schema object, and a list of warnings and
  errors encountered while parsing.
  """
  @spec new(Types.typeDictionary, [ParserWarning.t], [ParserError.t]) :: t
  def new(type_dict, warnings \\ [], errors \\ []) do
    %__MODULE__{type_dict: type_dict,
                warnings: warnings,
                errors: errors}
  end

  @doc ~S"""
  Merges two `ParserResult`s and adds any collisions errors from merging their
  type dictionaries to the list of errors in the merged `ParserResult`.

  """
  @spec merge(ParserResult.t, ParserResult.t) :: ParserResult.t
  def merge(
    %__MODULE__{type_dict: type_dict1, warnings: warnings1, errors: errors1},
    %__MODULE__{type_dict: type_dict2, warnings: warnings2, errors: errors2}
  ) do

    keys1 = type_dict1 |> Map.keys() |> MapSet.new()
    keys2 = type_dict2 |> Map.keys() |> MapSet.new()

    collisions =
      keys1
      |> MapSet.intersection(keys2)
      |> Enum.map(&ErrorUtil.name_collision/1)

    merged_type_dict = type_dict1 |> Map.merge(type_dict2)
    merged_warnings = warnings1 |> Enum.concat(warnings2)
    merged_errors = collisions |> Enum.concat(errors1) |> Enum.concat(errors2)

    %__MODULE__{type_dict: merged_type_dict,
                warnings: merged_warnings,
                errors: merged_errors}
  end
end

defmodule JS2E.Parsers.SchemaResult do
  @moduledoc ~S"""
  Represents the result of parsing a whole JSON schema including the parsed
  schema, along with all warnings and errors generated while parsing the schema
  and its members.
  """

  require Logger
  alias JS2E.Parsers.{ErrorUtil, ParserError, ParserWarning}
  alias JS2E.Types

  @type t :: %__MODULE__{schema_dict: Types.schemaDictionary,
                         warnings: [{Path.t, ParserWarning.t}],
                         errors: [{Path.t, ParserError.t}]}

  defstruct [:schema_dict, :warnings, :errors]

  @doc ~S"""
  Returns an empty `SchemaResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{schema_dict: %{}, warnings: [], errors: []}

  @doc ~S"""
  Constructs a new `SchemaResult`. A `SchemaResult` consists of a schema
  dictionary corresponding to the succesfully parsed JSON schema files,
  and a list of warnings and errors encountered while parsing.
  """
  @spec new(
    [{Path.t, Types.schemaDictionary}],
    [{Path.t, ParserWarning.t}],
    [{Path.t, ParserError.t}]
  )
  :: t
  def new(schema_dict, warnings \\ [], errors \\ []) do
    %__MODULE__{schema_dict: schema_dict,
                warnings: warnings,
                errors: errors}
  end

  @doc ~S"""
  Merges two `SchemaResult`s and adds any collisions errors from merging their
  schema dictionaries to the list of errors in the merged `SchemaResult`.

  """
  @spec merge(SchemaResult.t, SchemaResult.t) :: SchemaResult.t
  def merge(
    %__MODULE__{schema_dict: schema_dict1,
                warnings: warnings1,
                errors: errors1},
    %__MODULE__{schema_dict: schema_dict2,
                warnings: warnings2,
                errors: errors2}
  ) do

    keys1 = schema_dict1 |> Map.keys() |> MapSet.new()
    keys2 = schema_dict2 |> Map.keys() |> MapSet.new()

    collisions =
      keys1
      |> MapSet.intersection(keys2)
      |> Enum.map(&ErrorUtil.name_collision/1)

    merged_schema_dict = Map.merge(schema_dict1, schema_dict2)
    merged_warnings = warnings1 ++ warnings2
    merged_errors = collisions ++ errors1 ++ errors2

    %__MODULE__{schema_dict: merged_schema_dict,
                warnings: merged_warnings,
                errors: merged_errors}

  end
end
