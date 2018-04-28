defmodule JS2E.Printer.Utils.CommonOperations do
  @moduledoc ~S"""
  Module containing various utility functions
  for common operations across printers.
  """

  require Logger
  alias JS2E.Printer.PrinterError

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
