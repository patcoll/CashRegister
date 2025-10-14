defmodule CashRegister.Parser do
  @moduledoc """
  Parses input containing transaction data.
  """

  @type transaction :: {non_neg_integer(), non_neg_integer()}

  # Maximum allowed amount in cents ($100,000.00)
  @max_amount 10_000_000

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
            convert_and_validate_cents(decimal)
        end

      {_decimal, _remaining} ->
        {:error, "invalid amount format: #{amount_str}"}

      :error ->
        {:error, "invalid amount: #{amount_str}"}
    end
  end

  defp convert_and_validate_cents(decimal) do
    # Convert to cents: multiply by 100 and convert to integer
    cents =
      decimal
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_integer()

    if cents > @max_amount do
      max_amount_str = :erlang.float_to_binary(@max_amount / 100, decimals: 2)
      actual_amount_str = :erlang.float_to_binary(cents / 100, decimals: 2)
      {:error, "amount exceeds maximum allowed (#{max_amount_str}), got: #{actual_amount_str}"}
    else
      {:ok, cents}
    end
  end
end
