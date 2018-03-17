defmodule JS2E.Printer.Util do
  @moduledoc ~S"""
  A module containing utility function for JSON schema printers.
  """

  require Logger
  alias JS2E.{Types, TypePath}
  alias JS2E.Types.{PrimitiveType, SchemaDefinition}

  alias JS2E.Printer.{
    ErrorUtil,
    AllOfPrinter,
    AnyOfPrinter,
    ArrayPrinter,
    EnumPrinter,
    ObjectPrinter,
    OneOfPrinter,
    PrimitivePrinter,
    TuplePrinter,
    TypeReferencePrinter,
    UnionPrinter,
    PrinterResult
  }

  # Indentation, whitespace and casing - start

  @indent_size 4

  @doc ~S"""
  Returns a chunk of indentation.

  ## Examples

      iex> indent(2)
      "        "

  """
  @spec indent(pos_integer) :: String.t()
  def indent(tabs \\ 1) when is_integer(tabs) do
    String.pad_leading("", tabs * @indent_size)
  end

  @doc ~S"""
  Remove excessive newlines of a string.
  """
  @spec trim_newlines(String.t()) :: String.t()
  def trim_newlines(str) do
    String.trim(str) <> "\n"
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
  Upcases the first letter of a string.

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

  # Indentation, whitespace and casing - end

  # Printing types - start

  @spec create_type_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_type_name({:error, error}, _schema, _name), do: {:error, error}

  def create_type_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    type_name =
      if primitive_type?(resolved_type) do
        determine_primitive_type(resolved_type.type)
      else
        resolved_type_name = resolved_type.name

        if resolved_type_name == "#" do
          if resolved_schema.title != nil do
            {:ok, upcase_first(resolved_schema.title)}
          else
            {:ok, "Root"}
          end
        else
          {:ok, upcase_first(resolved_type_name)}
        end
      end

    case type_name do
      {:ok, type_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, qualify_name(resolved_schema, type_name, module_name)}
        else
          {:ok, type_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm type equivalent. Raises and error otherwise.

  ## Examples

  iex> determine_primitive_type("string")
  {:ok, "String"}

  iex> determine_primitive_type("integer")
  {:ok, "Int"}

  iex> determine_primitive_type("number")
  {:ok, "Float"}

  iex> determine_primitive_type("boolean")
  {:ok, "Bool"}

  iex> {:error, error} = determine_primitive_type("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type(type_name) do
    case type_name do
      "string" ->
        {:ok, "String"}

      "integer" ->
        {:ok, "Int"}

      "number" ->
        {:ok, "Float"}

      "boolean" ->
        {:ok, "Bool"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end

  # Printing types - end

  # Printing decoders - start

  @spec create_decoder_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_decoder_name({:error, error}, _schema, _name), do: {:error, error}

  def create_decoder_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    decoder_name =
      if primitive_type?(resolved_type) do
        determine_primitive_type_decoder(resolved_type.type)
      else
        type_name = resolved_type.name

        if type_name == "#" do
          if resolved_schema.title != nil do
            {:ok, "#{downcase_first(resolved_schema.title)}Decoder"}
          else
            {:ok, "rootDecoder"}
          end
        else
          {:ok, "#{type_name}Decoder"}
        end
      end

    case decoder_name do
      {:ok, decoder_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, qualify_name(resolved_schema, decoder_name, module_name)}
        else
          {:ok, decoder_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  and "boolean" into their Elm decoder equivalent. Raises an error otherwise.

  ## Examples

  iex> determine_primitive_type_decoder("string")
  {:ok, "Decode.string"}

  iex> determine_primitive_type_decoder("integer")
  {:ok, "Decode.int"}

  iex> determine_primitive_type_decoder("number")
  {:ok, "Decode.float"}

  iex> determine_primitive_type_decoder("boolean")
  {:ok, "Decode.bool"}

  iex> {:error, error} = determine_primitive_type_decoder("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type_decoder(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type_decoder(type_name) do
    case type_name do
      "string" ->
        {:ok, "Decode.string"}

      "integer" ->
        {:ok, "Decode.int"}

      "number" ->
        {:ok, "Decode.float"}

      "boolean" ->
        {:ok, "Decode.bool"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end

  # Printing decoders - end

  # Printing encoders - start

  @doc ~S"""
  Returns the encoder name given a JSON schema type definition.
  """
  @spec create_encoder_name(
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()},
          SchemaDefinition.t(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def create_encoder_name({:error, error}, _schema, _name), do: {:error, error}

  def create_encoder_name(
        {:ok, {resolved_type, resolved_schema}},
        context_schema,
        module_name
      ) do
    encoder_name_result =
      if primitive_type?(resolved_type) do
        determine_primitive_type_encoder(resolved_type.type)
      else
        type_name = resolved_type.name

        if type_name == "#" do
          if resolved_schema.title != nil do
            {:ok, "encode#{upcase_first(resolved_schema.title)}"}
          else
            {:ok, "encodeRoot"}
          end
        else
          {:ok, "encode#{upcase_first(type_name)}"}
        end
      end

    case encoder_name_result do
      {:ok, encoder_name} ->
        if resolved_schema.id != context_schema.id do
          {:ok, qualify_name(resolved_schema, encoder_name, module_name)}
        else
          {:ok, encoder_name}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc ~S"""
  Converts the following primitive types: "string", "integer", "number",
  "boolean", and "null" into their Elm encoder equivalent. Raises an error
  otherwise.

  ## Examples

  iex> determine_primitive_type_encoder("string")
  {:ok, "Encode.string"}

  iex> determine_primitive_type_encoder("integer")
  {:ok, "Encode.int"}

  iex> determine_primitive_type_encoder("number")
  {:ok, "Encode.float"}

  iex> determine_primitive_type_encoder("boolean")
  {:ok, "Encode.bool"}

  iex> determine_primitive_type_encoder("null")
  {:ok, "Encode.null"}

  iex> {:error, error} = determine_primitive_type_encoder("array")
  iex> error.error_type
  :unknown_primitive_type

  """
  @spec determine_primitive_type_encoder(String.t()) ::
          {:ok, String.t()} | {:error, PrinterError.t()}
  def determine_primitive_type_encoder(type_name) do
    case type_name do
      "string" ->
        {:ok, "Encode.string"}

      "integer" ->
        {:ok, "Encode.int"}

      "number" ->
        {:ok, "Encode.float"}

      "boolean" ->
        {:ok, "Encode.bool"}

      "null" ->
        {:ok, "Encode.null"}

      _ ->
        {:error, ErrorUtil.unknown_primitive_type(type_name)}
    end
  end

  # Printing encoders - end

  # Printing utils - start

  @spec qualify_name(SchemaDefinition.t(), String.t(), String.t()) :: String.t()
  def qualify_name(schema_def, type_name, module_name) do
    schema_name = schema_def.title

    if String.length(schema_name) > 0 do
      "#{module_name}.#{schema_name}.#{type_name}"
    else
      "#{module_name}.#{type_name}"
    end
  end

  @doc ~S"""
  Get the string shortname of the given struct.

  ## Examples

  iex> primitive_type = %JS2E.Types.PrimitiveType{name: "foo",
  ...>                                        path: ["#","foo"],
  ...>                                        type: "string"}
  ...> get_string_name(primitive_type)
  "PrimitiveType"

  """
  @spec get_string_name(struct) :: String.t()
  def get_string_name(instance) when is_map(instance) do
    instance.__struct__
    |> to_string
    |> String.split(".")
    |> List.last()
  end

  # Printing utils - end

  # Predicate functions - start

  @spec primitive_type?(struct) :: boolean
  def primitive_type?(type) do
    get_string_name(type) == "PrimitiveType"
  end

  @spec enum_type?(struct) :: boolean
  def enum_type?(type) do
    get_string_name(type) == "EnumType"
  end

  @spec one_of_type?(struct) :: boolean
  def one_of_type?(type) do
    get_string_name(type) == "OneOfType"
  end

  @spec union_type?(struct) :: boolean
  def union_type?(type) do
    get_string_name(type) == "UnionType"
  end

  # Predicate functions - end

  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(type_def, schema_def, schema_dict, module_name) do
    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_type/4,
      "AnyOfType" => &AnyOfPrinter.print_type/4,
      "ArrayType" => &ArrayPrinter.print_type/4,
      "EnumType" => &EnumPrinter.print_type/4,
      "ObjectType" => &ObjectPrinter.print_type/4,
      "OneOfType" => &OneOfPrinter.print_type/4,
      "PrimitiveType" => &PrimitivePrinter.print_type/4,
      "TupleType" => &TuplePrinter.print_type/4,
      "TypeReference" => &TypeReferencePrinter.print_type/4,
      "UnionType" => &UnionPrinter.print_type/4
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      type_printer = type_to_printer_dict[struct_name]
      type_printer.(type_def, schema_def, schema_dict, module_name)
    else
      PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(type_def, schema_def, schema_dict, module_name) do
    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_decoder/4,
      "AnyOfType" => &AnyOfPrinter.print_decoder/4,
      "ArrayType" => &ArrayPrinter.print_decoder/4,
      "EnumType" => &EnumPrinter.print_decoder/4,
      "ObjectType" => &ObjectPrinter.print_decoder/4,
      "OneOfType" => &OneOfPrinter.print_decoder/4,
      "PrimitiveType" => &PrimitivePrinter.print_decoder/4,
      "TupleType" => &TuplePrinter.print_decoder/4,
      "TypeReference" => &TypeReferencePrinter.print_decoder/4,
      "UnionType" => &UnionPrinter.print_decoder/4
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      decoder_printer = type_to_printer_dict[struct_name]
      decoder_printer.(type_def, schema_def, schema_dict, module_name)
    else
      PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: {:ok, String.t()} | {:error, PrinterError.t()}
  def print_encoder(type_def, schema_def, schema_dict, module_name) do
    type_to_printer_dict = %{
      "AllOfType" => &AllOfPrinter.print_encoder/4,
      "AnyOfType" => &AnyOfPrinter.print_encoder/4,
      "ArrayType" => &ArrayPrinter.print_encoder/4,
      "EnumType" => &EnumPrinter.print_encoder/4,
      "ObjectType" => &ObjectPrinter.print_encoder/4,
      "OneOfType" => &OneOfPrinter.print_encoder/4,
      "PrimitiveType" => &PrimitivePrinter.print_encoder/4,
      "TupleType" => &TuplePrinter.print_encoder/4,
      "TypeReference" => &TypeReferencePrinter.print_encoder/4,
      "UnionType" => &UnionPrinter.print_encoder/4
    }

    struct_name = get_string_name(type_def)

    if Map.has_key?(type_to_printer_dict, struct_name) do
      encoder_printer = type_to_printer_dict[struct_name]
      encoder_printer.(type_def, schema_def, schema_dict, module_name)
    else
      PrinterResult.new("", [ErrorUtil.unknown_type(struct_name)])
    end
  end

  @spec resolve_type(
          TypePath.t(),
          Types.typeIdentifier(),
          SchemaDefinition.t(),
          Types.schemaDictionary()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  def resolve_type(identifier, parent, schema_def, schema_dict) do
    resolved_result =
      cond do
        identifier in ["string", "number", "integer", "boolean"] ->
          resolve_primitive_identifier(identifier, schema_def)

        TypePath.type_path?(identifier) ->
          resolve_type_path_identifier(identifier, parent, schema_def)

        URI.parse(identifier).scheme != nil ->
          resolve_uri_identifier(identifier, parent, schema_dict)

        true ->
          {:error, ErrorUtil.unresolved_reference(identifier, parent)}
      end

    case resolved_result do
      {:ok, {resolved_type, resolved_schema_def}} ->
        if get_string_name(resolved_type) == "TypeReference" do
          resolve_type(
            resolved_type.path,
            parent,
            resolved_schema_def,
            schema_dict
          )
        else
          {:ok, {resolved_type, resolved_schema_def}}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec resolve_primitive_identifier(String.t(), SchemaDefinition.t()) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
  defp resolve_primitive_identifier(identifier, schema_def) do
    primitive_type = PrimitiveType.new(identifier, identifier, identifier)
    {:ok, {primitive_type, schema_def}}
  end

  @spec resolve_type_path_identifier(
          TypePath.t(),
          TypePath.t(),
          SchemaDefinition.t()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  defp resolve_type_path_identifier(identifier, parent, schema_def) do
    type_dict = schema_def.types
    resolved_type = type_dict[TypePath.to_string(identifier)]

    if resolved_type != nil do
      {:ok, {resolved_type, schema_def}}
    else
      {:error, ErrorUtil.unresolved_reference(identifier, parent)}
    end
  end

  @spec resolve_uri_identifier(
          TypePath.t(),
          String.t(),
          Types.schemaDictionary()
        ) ::
          {:ok, {Types.typeDefinition(), SchemaDefinition.t()}}
          | {:error, PrinterError.t()}
  defp resolve_uri_identifier(identifier, parent, schema_dict) do
    schema_id = determine_schema_id(identifier)
    schema_def = schema_dict[schema_id]

    if schema_def != nil do
      type_dict = schema_def.types

      resolved_type =
        if to_string(identifier) == schema_id do
          type_dict["#"]
        else
          type_dict[to_string(identifier)]
        end

      if resolved_type != nil do
        {:ok, {resolved_type, schema_def}}
      else
        {:error, ErrorUtil.unresolved_reference(identifier, parent)}
      end
    else
      {:error, ErrorUtil.unresolved_reference(identifier, parent)}
    end
  end

  @spec determine_schema_id(String.t()) :: String.t()
  defp determine_schema_id(identifier) do
    identifier
    |> URI.parse()
    |> Map.put(:fragment, nil)
    |> to_string
  end

  @spec split_ok_and_errors([{:ok, any} | {:error, PrinterError.t()}]) ::
          {[any], [PrinterError.t()]}
  def split_ok_and_errors(results) do
    results
    |> Enum.reverse()
    |> Enum.reduce({[], []}, fn result, {oks, errors} ->
      case result do
        {:ok, ok} ->
          {[ok | oks], errors}

        {:error, error} ->
          {oks, [error | errors]}
      end
    end)
  end
end
