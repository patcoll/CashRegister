defmodule CashRegister do
  @moduledoc """
  Main API for cash register operations.

  Processes transactions and calculates change.
  """

  alias CashRegister.{Calculator, Formatter, Parser}

  @doc """
  Processes a file containing transactions and returns formatted change output.

  Each line in the file should contain comma-separated owed,paid amounts.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
  """
  @spec process_file(String.t(), keyword()) :: list({:ok, String.t()} | {:error, String.t()})
  def process_file(file_path, opts \\ []) do
    file_path
    |> File.read!()
    |> Parser.parse_lines()
    |> Enum.map(fn tuple -> calculate_and_format(tuple, opts) end)
  end

  @doc """
  Processes a single transaction and returns formatted change.

  Returns `{:ok, formatted_change}` or `{:error, reason}`.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
  """
  @spec process_transaction(integer(), integer(), keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def process_transaction(owed_cents, paid_cents, opts \\ []) do
    calculate_and_format({owed_cents, paid_cents}, opts)
  end

  defp calculate_and_format({owed_cents, paid_cents}, opts) do
    case Calculator.calculate(owed_cents, paid_cents, opts) do
      {:ok, denominations} -> {:ok, Formatter.format(denominations)}
      {:error, reason} -> {:error, reason}
    end
  end
end
