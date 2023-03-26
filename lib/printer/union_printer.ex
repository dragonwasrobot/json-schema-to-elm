defmodule JS2E.Printer.UnionPrinter do
  @behaviour JS2E.Printer.PrinterBehaviour
  @moduledoc """
  A printer for printing an 'object' type decoder.
  """

  require Elixir.{EEx, Logger}
  alias JS2E.Printer
  alias JsonSchema.Types
  alias Printer.{PrinterResult, Utils}
  alias Types.{SchemaDefinition, UnionType}
  alias Utils.{ElmTypes, Indentation, Naming}

  @templates_location Application.compile_env(:js2e, :templates_location)

  # Type

  @type_location Path.join(@templates_location, "types/sum_type.elm.eex")
  EEx.function_from_file(:defp, :type_template, @type_location, [
    :sum_type
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_type(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_type(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    type_clauses =
      types
      |> create_type_clauses(name)

    type_name = name |> Naming.normalize_identifier(:upcase)

    %{name: type_name, clauses: {:named, type_clauses}}
    |> type_template()
    |> PrinterResult.new()
  end

  @spec create_type_clauses([UnionType.value_type()], String.t()) :: [ElmTypes.named_clause()]
  defp create_type_clauses(value_type, name) do
    value_type
    |> Enum.filter(&(&1 != :null))
    |> Enum.map(&to_type_clause(&1, name))
  end

  @spec to_type_clause(UnionType.value_type(), String.t()) :: ElmTypes.named_clause()
  defp to_type_clause(value_type, name) do
    type_name = Naming.normalize_identifier(name, :upcase)

    case value_type do
      :boolean -> %{name: "#{type_name}_B", type: "Bool"}
      :integer -> %{name: "#{type_name}_I", type: "Int"}
      :number -> %{name: "#{type_name}_F", type: "Float"}
      :string -> %{name: "#{type_name}_S", type: "String"}
    end
  end

  # Decoder

  @decoder_location Path.join(@templates_location, "decoders/sum_decoder.elm.eex")
  EEx.function_from_file(:defp, :decoder_template, @decoder_location, [
    :sum_decoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_decoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_decoder(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    normalized_name = Naming.normalize_identifier(name, :downcase)
    decoder_name = "#{normalized_name}Decoder"
    type_name = Naming.upcase_first(normalized_name)
    optional = :null in types
    decoder_type = check_if_maybe(type_name, optional)
    decoder_clauses = types |> create_decoder_clauses(type_name, optional)

    %{
      name: decoder_name,
      type: decoder_type,
      optional: optional,
      clauses: {:named, decoder_clauses}
    }
    |> decoder_template()
    |> PrinterResult.new()
  end

  @spec check_if_maybe(String.t(), boolean) :: String.t()
  defp check_if_maybe(type_name, optional) do
    if optional do
      "(Maybe #{type_name})"
    else
      type_name
    end
  end

  @spec create_decoder_clauses([UnionType.value_type()], String.t(), boolean) :: [
          decoder_clause()
        ]
  defp create_decoder_clauses(value_type, type_name, optional) do
    value_type
    |> Enum.filter(fn type_id -> type_id != :null end)
    |> Enum.map(&create_decoder_clause(&1, type_name, optional))
  end

  @type decoder_clause :: %{
          decoder_name: String.t(),
          constructor_name: String.t()
        }

  @spec create_decoder_clause(UnionType.value_type(), String.t(), boolean) :: decoder_clause()
  defp create_decoder_clause(value_type, type_name, optional) do
    {constructor_suffix, decoder_name} =
      case value_type do
        :boolean -> {"_B", "Decode.bool"}
        :integer -> {"_I", "Decode.int"}
        :number -> {"_F", "Decode.float"}
        :string -> {"_S", "Decode.string"}
      end

    constructor_name = type_name <> constructor_suffix

    constructor_name =
      if optional do
        "(#{constructor_name} >> Just)"
      else
        constructor_name
      end

    %{
      decoder_name: decoder_name,
      constructor_name: constructor_name
    }
  end

  # Encoder

  @encoder_location Path.join(@templates_location, "encoders/sum_encoder.elm.eex")
  EEx.function_from_file(:defp, :encoder_template, @encoder_location, [
    :sum_encoder
  ])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_encoder(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_encoder(
        %UnionType{name: name, path: _path, types: types},
        _schema_def,
        _schema_dict,
        _module_name
      ) do
    encoder_cases =
      types
      |> create_encoder_cases(name)

    type_name = Naming.normalize_identifier(name, :upcase)
    encoder_name = "encode#{type_name}"

    %{name: encoder_name, type: type_name, argument_name: name, cases: encoder_cases}
    |> encoder_template()
    |> Indentation.trim_newlines()
    |> PrinterResult.new()
  end

  @spec create_encoder_cases([UnionType.value_type()], String.t()) :: [encoder_case()]
  defp create_encoder_cases(value_types, name) do
    value_types
    |> Enum.map(&create_encoder_case(&1, name))
  end

  @type encoder_case :: %{
          constructor: String.t(),
          encoder: String.t()
        }

  @spec create_encoder_case(UnionType.value_type(), String.t()) :: encoder_case()
  defp create_encoder_case(value_type, name) do
    {constructor_suffix, encoder_name, argument_name} =
      case value_type do
        :boolean -> {"_B", "Encode.bool", "boolValue"}
        :integer -> {"_I", "Encode.int", "intValue"}
        :number -> {"_F", "Encode.float", "floatValue"}
        :string -> {"_S", "Encode.string", "stringValue"}
      end

    constructor_name = Naming.normalize_identifier(name, :upcase) <> constructor_suffix

    %{
      constructor: "#{constructor_name} #{argument_name}",
      encoder: "#{encoder_name} #{argument_name}"
    }
  end

  # Fuzzer

  @fuzzer_location Path.join(@templates_location, "fuzzers/sum_fuzzer.elm.eex")
  EEx.function_from_file(:defp, :fuzzer_template, @fuzzer_location, [:sum_fuzzer])

  @impl JS2E.Printer.PrinterBehaviour
  @spec print_fuzzer(
          Types.typeDefinition(),
          SchemaDefinition.t(),
          Types.schemaDictionary(),
          String.t()
        ) :: PrinterResult.t()
  def print_fuzzer(
        %UnionType{name: name, path: _path, types: types},
        schema_def,
        _schema_dict,
        _module_name
      ) do
    type_name = Naming.create_root_name(name, schema_def)
    argument_name = Naming.normalize_identifier(type_name, :downcase)
    decoder_name = "#{Naming.normalize_identifier(type_name, :downcase)}Decoder"
    encoder_name = "encode#{Naming.normalize_identifier(type_name, :upcase)}"
    fuzzer_name = "#{Naming.normalize_identifier(type_name, :downcase)}Fuzzer"

    fuzzers =
      types
      |> Enum.map(fn value_type -> to_clause_fuzzer(value_type, type_name) end)

    %{
      name: fuzzer_name,
      type: type_name,
      argument_name: argument_name,
      encoder_name: encoder_name,
      decoder_name: decoder_name,
      clause_fuzzers: List.flatten(fuzzers)
    }
    |> fuzzer_template()
    |> PrinterResult.new()
  end

  @type clause_fuzzer :: String.t()

  @spec to_clause_fuzzer(UnionType.value_type(), String.t()) :: clause_fuzzer()
  defp to_clause_fuzzer(value_type, type_name) do
    primitive_fuzzer = primitive_type_to_fuzzer(value_type)

    case value_type do
      :boolean -> "Fuzz.map #{type_name}_B #{primitive_fuzzer}"
      :integer -> "Fuzz.map #{type_name}_I #{primitive_fuzzer}"
      :number -> "Fuzz.map #{type_name}_F #{primitive_fuzzer}"
      :string -> "Fuzz.map #{type_name}_S #{primitive_fuzzer}"
    end
  end

  @spec primitive_type_to_fuzzer(UnionType.value_type()) :: clause_fuzzer()
  defp primitive_type_to_fuzzer(value_type) do
    case value_type do
      :boolean -> "Fuzz.bool"
      :integer -> "Fuzz.int"
      :number -> "Fuzz.niceFloat"
      :string -> "Fuzz.string"
    end
  end
end
