defmodule CashRegister.Parser do
  @moduledoc """
  Parses input containing transaction data.
  """

  alias CashRegister.Error

  @type transaction :: {non_neg_integer(), non_neg_integer()}

  # Maximum allowed amount in cents ($100,000.00)
  @max_amount 10_000_000

  @doc """
  Parses a line of input into {owed_cents, paid_cents}.

  Supports both US format ("1.00,2.00") and international format ("1,00,2,00").
  Format is automatically detected based on comma count.
  """
  @spec parse_line(String.t()) :: {:ok, transaction()} | {:error, Error.t()}
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
        {:error, {:invalid_line_format, %{line: line}}}
    end
  end

  @doc """
  Parses multiple lines from file content.

  Skips empty lines and supports mixed US and international formats.
  """
  @spec parse_lines(String.t()) :: list(transaction()) | {:error, Error.t()}
  def parse_lines(content) do
    results =
      content
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_line/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        Enum.map(results, fn {:ok, transaction} -> transaction end)

      error ->
        error
    end
  end

  defp parse_amount(amount_str) do
    amount_str = String.trim(amount_str)

    cond do
      String.ends_with?(amount_str, ".") ->
        {:error,
         {:invalid_amount_format,
          %{amount: amount_str, reason: "missing cents after decimal point"}}}

      length(String.split(amount_str, ".")) > 2 ->
        {:error,
         {:invalid_amount_format, %{amount: amount_str, reason: "multiple decimal points"}}}

      true ->
        parse_with_decimal(amount_str)
    end
  end

  defp parse_with_decimal(amount_str) do
    case Decimal.parse(amount_str) do
      {decimal, ""} ->
        cond do
          Decimal.negative?(decimal) ->
            {:error, {:invalid_amount_format, %{amount: amount_str, reason: "negative amount"}}}

          not Decimal.equal?(decimal, Decimal.round(decimal, 2)) ->
            {:error,
             {:invalid_amount_format, %{amount: amount_str, reason: "too many decimal places"}}}

          true ->
            convert_and_validate_cents(decimal)
        end

      {_decimal, remaining} when remaining != "" ->
        {:error, {:invalid_amount_format, %{amount: amount_str, reason: "trailing characters"}}}

      :error ->
        {:error, {:invalid_amount_format, %{amount: amount_str, reason: "not a number"}}}
    end
  end

  defp convert_and_validate_cents(decimal) do
    cents =
      decimal
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_integer()

    if cents > @max_amount do
      max_amount_str = :erlang.float_to_binary(@max_amount / 100, decimals: 2)
      actual_amount_str = :erlang.float_to_binary(cents / 100, decimals: 2)

      {:error,
       {:invalid_amount_format,
        %{amount: actual_amount_str, reason: "exceeds maximum allowed (#{max_amount_str})"}}}
    else
      {:ok, cents}
    end
  end
end
