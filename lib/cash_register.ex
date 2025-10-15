defmodule CashRegister do
  @moduledoc """
  Main API for cash register operations.

  Processes transactions and calculates change.
  """

  alias CashRegister.{Error, Parser, Transactions}

  @doc """
  Processes a file containing transactions and returns formatted change output.

  Each line in the file should contain comma-separated owed,paid amounts.

  Returns a list of formatted strings if all transactions succeed, or the first
  error encountered (including file read errors).

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec process_file(String.t(), keyword()) :: list(String.t()) | {:error, Error.t()}
  def process_file(file_path, opts \\ []) do
    with {:ok, content} <- File.read(file_path),
         {:ok, transactions} <- validate_parse_result(Parser.parse_lines(content)) do
      process_transactions(transactions, opts)
    else
      {:error, reason} when is_atom(reason) ->
        {:error, {:file_read_error, %{path: file_path, reason: reason}}}

      {:error, _} = error ->
        error
    end
  end

  defp validate_parse_result({:error, _} = error), do: error
  defp validate_parse_result(transactions), do: {:ok, transactions}

  defp process_transactions(transactions, opts) do
    results =
      Enum.map(transactions, fn {owed, paid} ->
        Transactions.transact(owed, paid, opts)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        Enum.map(results, fn {:ok, formatted} -> formatted end)

      error ->
        error
    end
  end

  @doc """
  Processes a file containing transactions and writes formatted change output to a file.

  Each line in the input file should contain comma-separated owed,paid amounts.
  Each line in the output file will contain the formatted change for that transaction.

  Returns `:ok` if successful, or `{:error, reason}` if reading, processing, or writing fails.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec process_file_and_output(String.t(), String.t(), keyword()) ::
          :ok | {:error, Error.t()}
  def process_file_and_output(input_path, output_path, opts \\ []) do
    case process_file(input_path, opts) do
      {:error, _} = error ->
        error

      results when is_list(results) ->
        content = Enum.join(results, "\n")

        case File.write(output_path, content) do
          :ok ->
            :ok

          {:error, reason} ->
            {:error, {:file_write_error, %{path: output_path, reason: reason}}}
        end
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
          {:ok, String.t()} | {:error, Error.t()}
  def process_transaction(owed_cents, paid_cents, opts \\ []) do
    Transactions.transact(owed_cents, paid_cents, opts)
  end
end
