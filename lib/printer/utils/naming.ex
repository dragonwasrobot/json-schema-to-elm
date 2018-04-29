defmodule JS2E.Printer.Utils.Naming do
  @moduledoc ~S"""
  Module containing various utility functions for normalizing names of
  identifiers in the Elm output.
  """

  alias JS2E.Types.SchemaDefinition

  @spec qualify_name(SchemaDefinition.t(), String.t(), String.t()) :: String.t()
  def qualify_name(schema_def, type_name, module_name) do
    schema_name = schema_def.title

    if String.length(schema_name) > 0 do
      "#{module_name}.#{schema_name}.#{type_name}"
    else
      "#{module_name}.#{type_name}"
    end
  end

  @type casing :: :upcase | :downcase | :none

  @doc ~S"""
  Normalizes a given identifier, i.e. translates numbers into plain
  text, e.g. '0' becomes 'zero', and translates symbols into plain text,
  e.g. '@' becomes 'at'.

  Also turns kebab-case, snake_case, and space case into camelCase.

  ## Examples

      iex> normalize_identifier("0")
      "zero"

      iex> normalize_identifier("shape")
      "shape"

      iex> normalize_identifier("myAngry!!Name")
      "myAngryBangBangName"

      iex> normalize_identifier("name@Domain")
      "nameAtDomain"

      iex> normalize_identifier("#Browns")
      "hashBrowns"

      iex> normalize_identifier("$Bill")
      "dollarBill"

      iex> normalize_identifier("identity")
      "identity"

      iex> normalize_identifier("i want to be camel cased")
      "iWantToBeCamelCased"

      iex> normalize_identifier("i-want-to-be-camel-cased")
      "iWantToBeCamelCased"

      iex> normalize_identifier("DontEverChange")
      "dontEverChange"

      iex> normalize_identifier("i_want_to_be_camel_cased")
      "iWantToBeCamelCased"

  """
  @spec normalize_identifier(String.t(), casing) :: String.t()
  def normalize_identifier(identifier, casing \\ :none) do
    normalized_identifier =
      identifier
      |> kebab_to_camel_case
      |> snake_to_camel_case
      |> space_to_camel_case
      |> normalize_name
      |> normalize_symbols
      |> downcase_first

    case casing do
      :none ->
        if determine_case(identifier) == :upcase do
          upcase_first(normalized_identifier)
        else
          # We prefer to downcase
          downcase_first(normalized_identifier)
        end

      :upcase ->
        upcase_first(normalized_identifier)

      :downcase ->
        downcase_first(normalized_identifier)
    end
  end

  # Determines the casing of a string, e.g.
  # - the string `"Abc"` returns `:upcase`,
  # - the string `"abc"` returns `:downcase`, and
  # - the string `"$bc"` returns `:none`
  defp determine_case(s) do
    first = s

    cond do
      first |> String.upcase() == first and first |> String.downcase() != first ->
        :upcase

      first |> String.upcase() != first and first |> String.downcase() == first ->
        :downcase

      true ->
        :none
    end
  end

  # Prettifies anonymous schema names like `0` and `1` into - slightly -
  # better names like `zero` and `one`
  @spec normalize_name(String.t()) :: String.t()
  defp normalize_name("0"), do: "zero"
  defp normalize_name("1"), do: "one"
  defp normalize_name("2"), do: "two"
  defp normalize_name("3"), do: "three"
  defp normalize_name("4"), do: "four"
  defp normalize_name("5"), do: "five"
  defp normalize_name("6"), do: "six"
  defp normalize_name("7"), do: "seven"
  defp normalize_name("8"), do: "eight"
  defp normalize_name("9"), do: "nine"
  defp normalize_name("10"), do: "ten"
  defp normalize_name(name), do: downcase_first(name)

  # Filters out or translates all symbols that the Elm compiler does not allow
  # in an identifier:

  #     ?!@#$%^&*()[]{}\/<>|`'",.+~=:;

  # into something more Elm parser friendly. Note that hyphens (-) and
  # underscores (_) should be converted to camelCase using the appropriate
  # helper functions.
  @spec normalize_symbols(String.t()) :: String.t()
  defp normalize_symbols(str) do
    str
    |> String.replace("?", "Huh")
    |> String.replace("!", "Bang")
    |> String.replace("@", "At")
    |> String.replace("#", "Hash")
    |> String.replace("$", "Dollar")
    |> String.replace("%", "Percent")
    |> String.replace("^", "Hat")
    |> String.replace("&", "And")
    |> String.replace("*", "Times")
    |> String.replace("(", "LParen")
    |> String.replace(")", "RParen")
    |> String.replace("[", "LBracket")
    |> String.replace("]", "RBracket")
    |> String.replace("{", "LBrace")
    |> String.replace("}", "RBrace")
    |> String.replace("<", "Lt")
    |> String.replace(">", "Gt")
    |> String.replace("\\", "Backslash")
    |> String.replace("/", "Slash")
    |> String.replace("|", "Pipe")
    |> String.replace("`", "Tick")
    |> String.replace("'", "Quote")
    |> String.replace("\"", "DoubleQuote")
    |> String.replace(".", "Dot")
    |> String.replace(",", "Comma")
    |> String.replace("-", "Minus")
    |> String.replace("+", "Plus")
    |> String.replace("~", "Tilde")
    |> String.replace("=", "Equal")
    |> String.replace(":", "Colon")
    |> String.replace(";", "Semicolon")
  end

  # Turns a kebab-cased identifier into a camelCased one
  @spec kebab_to_camel_case(String.t()) :: String.t()
  defp kebab_to_camel_case(str) do
    str
    |> String.split("-")
    |> Enum.map(fn word -> upcase_first(word) end)
    |> Enum.join()
  end

  # Turns a snake_cased identifier into a camelCased one
  @spec snake_to_camel_case(String.t()) :: String.t()
  defp snake_to_camel_case(str) do
    str
    |> String.split("_")
    |> Enum.map(fn word -> upcase_first(word) end)
    |> Enum.join()
  end

  # Turns a space cased identifier into a camelCased one
  @spec space_to_camel_case(String.t()) :: String.t()
  defp space_to_camel_case(str) do
    str
    |> String.split(" ")
    |> Enum.map(fn word -> upcase_first(word) end)
    |> Enum.join()
  end

  @doc ~S"""
  Upcases the first letter of a string.

  ## Examples

  iex> upcase_first("foobar")
  "Foobar"

  """
  @spec upcase_first(String.t()) :: String.t()
  def upcase_first(string) when is_binary(string) do
    if String.length(string) > 0 do
      String.upcase(String.at(string, 0)) <> String.slice(string, 1..-1)
    else
      ""
    end
  end

  @doc ~S"""
  Downcases the first letter of a string.

  ## Examples

  iex> downcase_first("Foobar")
  "foobar"

  """
  @spec downcase_first(String.t()) :: String.t()
  def downcase_first(string) when is_binary(string) do
    if String.length(string) > 0 do
      String.downcase(String.at(string, 0)) <> String.slice(string, 1..-1)
    else
      ""
    end
  end
end
