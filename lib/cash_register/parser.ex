defmodule CashRegister.Parser do
  @moduledoc """
  Parses input containing transaction data.
  """

  @type transaction :: {non_neg_integer(), non_neg_integer()}

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

  Skips empty lines. Returns a list of transactions if all lines are valid,
  or returns the first error tuple if any line is invalid.

  Supports mixed US and international formats in the same input.
  """
  @spec parse_lines(String.t()) :: list(transaction()) | {:error, String.t()}
  def parse_lines(content) do
    results =
      content
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_line/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        # No errors, unwrap all the :ok tuples
        Enum.map(results, fn {:ok, transaction} -> transaction end)

      error ->
        error
    end
  end

  defp parse_amount(amount_str) do
    amount_str = String.trim(amount_str)

    cond do
      # Check for missing cents after decimal point: "1."
      String.ends_with?(amount_str, ".") ->
        {:error, "missing cents after decimal point: #{amount_str}"}

      # Check for multiple decimal points: "1.2.3"
      length(String.split(amount_str, ".")) > 2 ->
        {:error, "invalid amount format (multiple decimal points): #{amount_str}"}

      true ->
        parse_with_decimal(amount_str)
    end
  end

  defp parse_with_decimal(amount_str) do
    case Decimal.parse(amount_str) do
      {decimal, ""} ->
        cond do
          Decimal.negative?(decimal) ->
            {:error, "amount must be non-negative, got: #{amount_str}"}

          # Check for more than 2 decimal places by comparing with rounded value
          not Decimal.equal?(decimal, Decimal.round(decimal, 2)) ->
            {:error, "too many decimal places (max 2): #{amount_str}"}

          true ->
            # Convert to cents: multiply by 100 and convert to integer
            cents =
              decimal
              |> Decimal.mult(100)
              |> Decimal.round(0)
              |> Decimal.to_integer()

            {:ok, cents}
        end

      {_decimal, _remaining} ->
        {:error, "invalid amount format: #{amount_str}"}

      :error ->
        {:error, "invalid amount: #{amount_str}"}
    end
  end

  @doc """
  Parses a formatted change string back into change items.

  Returns `{:ok, change_items}` or `{:error, reason}`.

  Each change item has the count (not value) in position 2.
  """
  @spec parse_change_result(String.t()) ::
          {:ok, list(CashRegister.ChangeStrategy.change_item())} | {:error, String.t()}
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
    with [count_str, name] <- String.split(String.trim(part), " ", parts: 2),
         {count, ""} when count > 0 <- Integer.parse(count_str),
         denomination_id = singularize_denomination(name),
         {:ok, {id, _value, singular, plural}} <- lookup_denomination_info(denomination_id) do
      {:ok, {id, count, singular, plural}}
    else
      [_] -> {:error, :invalid_format}
      _ -> {:error, :invalid_count}
    end
  end

  defp singularize_denomination(name) do
    cond do
      String.ends_with?(name, "pennies") -> "penny"
      String.ends_with?(name, " coins") -> String.trim_trailing(name, " coins")
      String.ends_with?(name, " coin") -> String.trim_trailing(name, " coin")
      String.ends_with?(name, "s") -> String.trim_trailing(name, "s")
      true -> name
    end
  end

  defp lookup_denomination_info(id) do
    # Build a lookup map from all supported currencies
    denominations =
      CashRegister.Currency.supported()
      |> Enum.flat_map(fn currency ->
        CashRegister.Currency.denominations(currency)
      end)

    case Enum.find(denominations, fn {denom_id, _value, _singular, _plural} -> denom_id == id end) do
      nil -> :error
      denom -> {:ok, denom}
    end
  end
end
