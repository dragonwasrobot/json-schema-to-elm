defmodule JS2E.Printers.PrinterError do
  @moduledoc ~S"""
  Represents an error generated while printing a JSON schema object
  as Elm code.
  """

  alias JS2E.Types

  @type t :: %__MODULE__{identifier: Types.typeIdentifier,
                         error_type: atom,
                         message: String.t}

  defstruct [:identifier, :error_type, :message]

  @doc ~S"""
  Constructs a `PrinterError`.
  """
  @spec new(Types.typeIdentifier, atom, String.t) :: t
  def new(identifier, error_type, message) do
    %__MODULE__{identifier: identifier,
                error_type: error_type,
                message: message}
  end

  @doc ~S"""
  Pretty prints a `PrinterError`.
  """
  @spec print(t, Path.t) :: String.t
  def print(%__MODULE__{identifier: identifier,
                        error_type: error_type,
                        message: message}, file_path) do
    "('#{file_path}#{identifier}'): #{message}"
  end
end

defmodule JS2E.Printers.PrinterResult do
  @moduledoc ~S"""
  Represents the result of printing a subset of a JSON schema as Elm code
  including printed schema, warnings, and errors.
  """

  require Logger
  alias JS2E.Printers.PrinterError

  @type t :: %__MODULE__{printed_schema: String.t,
                         errors: [PrinterError.t]}

  defstruct [:printed_schema, :errors]

  @doc ~S"""
  Returns an empty `PrinterResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{printed_schema: "", errors: []}

  @doc ~S"""
  Creates a `PrinterResult`.
  """
  @spec new(String.t, [PrinterError.t]) :: t
  def new(printed_schema, errors \\ []) do
    %__MODULE__{printed_schema: printed_schema,
                errors: errors}
  end

  @doc ~S"""
  Merges two `PrinterResult`s and adds any errors from merging their file
  dictionaries to the list of errors in the merged `PrinterResult`.

  """
  @spec merge(PrinterResult.t, PrinterResult.t) :: PrinterResult.t
  def merge(
    %__MODULE__{printed_schema: printed_schema1, errors: errors1},
    %__MODULE__{printed_schema: printed_schema2, errors: errors2}) do

    merged_schema = String.trim(printed_schema1) <>
      "\n\n\n" <> String.trim(printed_schema2)
    merged_errors = Enum.uniq(errors1 ++ errors2)

    %__MODULE__{printed_schema: merged_schema,
                errors: merged_errors}
  end

end

defmodule JS2E.Printers.SchemaResult do
  @moduledoc ~S"""
  Represents the result of printing a whole JSON schema document as Elm code
  including printed schema, warnings, and errors.
  """

  require Logger
  alias JS2E.Printers.PrinterError
  alias JS2E.Types

  @type t :: %__MODULE__{file_dict: Types.fileDictionary,
                         errors: [{Path.t, PrinterError.t}]}

  defstruct [:file_dict, :errors]

  @doc ~S"""
  Returns an empty `SchemaResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{file_dict: %{}, errors: []}

  @doc ~S"""
  Creates a `SchemaResult`.
  """
  @spec new(Types.fileDictionary, [PrinterError.t]) :: t
  def new(file_dict, errors \\ []) do
    %__MODULE__{file_dict: file_dict,
                errors: errors}
  end

  @doc ~S"""
  Merges two `SchemaResult`s and adds any errors from merging their file
  dictionaries to the list of errors in the merged `SchemaResult`.

  """
  @spec merge(SchemaResult.t, SchemaResult.t) :: SchemaResult.t
  def merge(
    %__MODULE__{file_dict: file_dict1,
                errors: errors1},
    %__MODULE__{file_dict: file_dict2,
                errors: errors2}) do

    keys1 = file_dict1 |> Map.keys() |> MapSet.new()
    keys2 = file_dict2 |> Map.keys() |> MapSet.new()

    merged_file_dict = Map.merge(file_dict1, file_dict2)
    merged_errors = errors1 ++ errors2

    %__MODULE__{file_dict: merged_file_dict,
                errors: merged_errors}
  end

end
