defmodule CashRegister do
  @moduledoc """
  Main API for cash register operations.

  Processes transactions and calculates change.
  """

  alias CashRegister.{Calculator, Formatter, Parser}

  @doc """
  Processes a file containing transactions and returns formatted change output.

  Each line in the file should contain comma-separated owed,paid amounts.

  Returns a list of result tuples for successful file reads, or a plain error tuple
  if the file cannot be read.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec process_file(String.t(), keyword()) ::
          list({:ok, String.t()} | {:error, String.t()}) | {:error, String.t()}
  def process_file(file_path, opts \\ []) do
    case File.read(file_path) do
      {:ok, content} ->
        case Parser.parse_lines(content) do
          {:error, reason} ->
            {:error, reason}

          transactions ->
            Enum.map(transactions, &calculate_and_format(&1, opts))
        end

      {:error, reason} ->
        {:error, "cannot read file #{file_path}: #{:file.format_error(reason)}"}
    end
  end

  @doc """
  Processes a single transaction and returns formatted change.

  Returns `{:ok, formatted_change}` or `{:error, reason}`.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
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
