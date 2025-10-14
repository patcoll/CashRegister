defmodule CashRegister.Parser do
  @moduledoc """
  Parses input containing transaction data.
  """

  @typep transaction :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Parses a line of input into {owed_cents, paid_cents}.

  Supports both US format ("1.00,2.00") and international format ("1,00,2,00").
  Format is automatically detected based on comma count.

  Returns `{:ok, {owed_cents, paid_cents}}` or `{:error, reason}`.
  """
  @spec parse_line(String.t()) :: {:ok, transaction()} | {:error, String.t()}
  def parse_line(line) do
    line
    |> String.trim()
    |> String.split(",")
    |> case do
      [owed_str, paid_str] ->
        with {:ok, owed} <- parse_amount(owed_str),
             {:ok, paid} <- parse_amount(paid_str) do
          {:ok, {owed, paid}}
        end

      [o1, o2, p1, p2] ->
        owed_str = "#{o1}.#{o2}"
        paid_str = "#{p1}.#{p2}"

        with {:ok, owed} <- parse_amount(owed_str),
             {:ok, paid} <- parse_amount(paid_str) do
          {:ok, {owed, paid}}
        end

      _invalid ->
        {:error, "invalid line format: #{line}"}
    end
  end

  @doc """
  Parses multiple lines from file content.

  Skips empty lines. Raises `ArgumentError` on the first parse error.

  Supports mixed US and international formats in the same input.
  """
  @spec parse_lines(String.t()) :: list(transaction())
  def parse_lines(content) do
    content
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case parse_line(line) do
        {:ok, transaction} ->
          transaction

        {:error, reason} ->
          raise ArgumentError, reason
      end
    end)
  end

  defp parse_amount(amount_str) do
    amount_str = String.trim(amount_str)

    case Float.parse(amount_str) do
      {amount, ""} when amount >= 0 ->
        cents = round(amount * 100)
        {:ok, cents}

      {_amount, _} ->
        {:error, "invalid amount format: #{amount_str}"}

      :error ->
        {:error, "invalid amount: #{amount_str}"}
    end
  end

  @doc """
  Parses a formatted change string back into denominations.

  Returns `{:ok, denominations}` or `{:error, reason}`.
  """
  @spec parse_change_result(String.t()) ::
          {:ok, list(CashRegister.Currency.denomination())} | {:error, String.t()}
  def parse_change_result(result_string) do
    trimmed = String.trim(result_string)

    if trimmed == "" or trimmed == "no change" do
      {:ok, []}
    else
      parse_denominations(trimmed)
    end
  end

  defp parse_denominations(result_string) do
    result_string
    |> String.split(",")
    |> Enum.reduce_while({:ok, []}, fn part, {:ok, acc} ->
      case parse_denomination_part(part) do
        {:ok, denomination} -> {:cont, {:ok, [denomination | acc]}}
        {:error, _reason} -> {:halt, {:error, "invalid change format: #{result_string}"}}
      end
    end)
    |> case do
      {:ok, denominations} -> {:ok, Enum.reverse(denominations)}
      error -> error
    end
  end

  defp parse_denomination_part(part) do
    case String.split(String.trim(part), " ", parts: 2) do
      [count_str, name] ->
        case Integer.parse(count_str) do
          {count, ""} when count > 0 ->
            {:ok, {singularize_denomination(name), count}}

          _other ->
            {:error, :invalid_count}
        end

      _other ->
        {:error, :invalid_format}
    end
  end

  defp singularize_denomination(name) do
    cond do
      String.ends_with?(name, "pennies") -> "penny"
      String.ends_with?(name, "s") -> String.trim_trailing(name, "s")
      true -> name
    end
  end
end
