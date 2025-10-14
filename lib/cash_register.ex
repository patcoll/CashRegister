defmodule CashRegister do
  @moduledoc """
  Main API for cash register operations.

  Processes transactions and calculates change.
  """

  alias CashRegister.{Calculator, Formatter, Parser}

  @doc """
  Processes a file containing transactions and returns formatted change output.

  Each line in the file should contain comma-separated owed,paid amounts.
  """
  @spec process_file(String.t()) :: list({:ok, String.t()} | {:error, String.t()})
  def process_file(file_path) do
    file_path
    |> File.read!()
    |> Parser.parse_lines()
    |> Enum.map(&calculate_and_format/1)
  end

  @doc """
  Processes a single transaction and returns formatted change.

  ## Examples

  ```elixir
  iex> CashRegister.process_transaction(212, 300)
  {:ok, "3 quarters,1 dime,3 pennies"}

  iex> CashRegister.process_transaction(300, 200)
  {:error, "insufficient payment: paid 200 cents < owed 300 cents"}
  ```
  """
  @spec process_transaction(integer(), integer()) :: {:ok, String.t()} | {:error, String.t()}
  def process_transaction(owed_cents, paid_cents) do
    calculate_and_format({owed_cents, paid_cents})
  end

  defp calculate_and_format({owed_cents, paid_cents}) do
    case Calculator.calculate(owed_cents, paid_cents) do
      {:ok, denominations} -> {:ok, Formatter.format(denominations)}
      {:error, reason} -> {:error, reason}
    end
  end
end
