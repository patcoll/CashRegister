defmodule CashRegister do
  @moduledoc """
  Main API for cash register operations.

  Processes transactions and calculates change.
  """

  alias CashRegister.{Calculator, Formatter, Parser}

  @doc """
  Processes a file containing transactions and returns formatted change output.

  Each line in the file should contain comma-separated owed,paid amounts.

  Returns a list of formatted strings if all transactions succeed, or the first
  error encountered (including file read errors).

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec process_file(String.t(), keyword()) :: list(String.t()) | {:error, String.t()}
  def process_file(file_path, opts \\ []) do
    with {:ok, content} <- File.read(file_path),
         {:ok, transactions} <- validate_parse_result(Parser.parse_lines(content)) do
      process_transactions(transactions, opts)
    else
      {:error, :enoent} ->
        {:error, "cannot read file #{file_path}: no such file or directory"}

      {:error, reason} when is_atom(reason) ->
        {:error, "cannot read file #{file_path}: #{:file.format_error(reason)}"}

      {:error, message} when is_binary(message) ->
        {:error, message}
    end
  end

  defp validate_parse_result({:error, _} = error), do: error
  defp validate_parse_result(transactions), do: {:ok, transactions}

  defp process_transactions(transactions, opts) do
    results = Enum.map(transactions, &calculate_and_format(&1, opts))

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        # No errors, unwrap all the :ok tuples
        Enum.map(results, fn {:ok, formatted} -> formatted end)

      error ->
        error
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
