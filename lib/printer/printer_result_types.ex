defmodule JS2E.Printer.PrinterError do
  @moduledoc ~S"""
  Represents an error generated while printing a JSON schema object
  as Elm code.
  """

  alias JsonSchema.Types

  @type t :: %__MODULE__{
          identifier: Types.typeIdentifier(),
          error_type: atom,
          message: String.t()
        }

  defstruct [:identifier, :error_type, :message]

  @doc ~S"""
  Constructs a `PrinterError`.
  """
  @spec new(Types.typeIdentifier(), atom, String.t()) :: t
  def new(identifier, error_type, message) do
    %__MODULE__{
      identifier: identifier,
      error_type: error_type,
      message: message
    }
  end
end

defmodule JS2E.Printer.PrinterResult do
  @moduledoc ~S"""
  Represents the result of printing a subset of a JSON schema as Elm code
  including printed schema, warnings, and errors.
  """

  require Logger
  alias JS2E.Printer.PrinterError

  @type t :: %__MODULE__{printed_schema: String.t(), errors: [PrinterError.t()]}

  defstruct [:printed_schema, :errors]

  @doc ~S"""
  Returns an empty `PrinterResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{printed_schema: "", errors: []}

  @doc ~S"""
  Creates a `PrinterResult`.
  """
  @spec new(String.t(), [PrinterError.t()]) :: t
  def new(printed_schema, errors \\ []) do
    %__MODULE__{printed_schema: printed_schema, errors: errors}
  end

  @doc ~S"""
  Merges two `PrinterResult`s and adds any errors from merging their file
  dictionaries to the list of errors in the merged `PrinterResult`.

  """
  @spec merge(t, t) :: t
  def merge(result1, result2) do
    merged_schema =
      String.trim(result1.printed_schema) <> "\n\n\n" <> String.trim(result2.printed_schema)

    merged_errors = Enum.uniq(result1.errors ++ result2.errors)

    new(merged_schema, merged_errors)
  end
end

defmodule JS2E.Printer.SchemaResult do
  @moduledoc ~S"""
  Represents the result of printing a whole JSON schema document as Elm code
  including printed schema, warnings, and errors.
  """

  require Logger
  alias JS2E.Printer.PrinterError
  alias JsonSchema.Types

  @type t :: %__MODULE__{
          file_dict: Types.fileDictionary(),
          errors: [{Path.t(), PrinterError.t()}]
        }

  defstruct [:file_dict, :errors]

  @doc ~S"""
  Returns an empty `SchemaResult`.
  """
  @spec new :: t
  def new, do: %__MODULE__{file_dict: %{}, errors: []}

  @doc ~S"""
  Creates a `SchemaResult`.
  """
  @spec new(Types.fileDictionary(), [PrinterError.t()]) :: t
  def new(file_dict, errors \\ []) do
    %__MODULE__{file_dict: file_dict, errors: errors}
  end

  @doc ~S"""
  Merges two `SchemaResult`s and adds any errors from merging their file
  dictionaries to the list of errors in the merged `SchemaResult`.

  """
  @spec merge(t, t) :: t
  def merge(result1, result2) do
    merged_file_dict = Map.merge(result1.file_dict, result2.file_dict)
    merged_errors = result1.errors ++ result2.errors

    %__MODULE__{file_dict: merged_file_dict, errors: merged_errors}
  end
end
