defmodule CashRegister.DenominationHelpers do
  @moduledoc """
  Shared test helpers for working with denomination lists.
  """

  alias CashRegister.Currency

  @doc """
  Asserts that a list of denominations sums to the expected total in cents.

  Supports multiple currencies by detecting denomination names automatically.
  """
  defmacro assert_correct_total(denominations, expected_cents) do
    quote do
      total = CashRegister.DenominationHelpers.calculate_total(unquote(denominations))
      assert total == unquote(expected_cents)
    end
  end

  @doc """
  Calculates the total value in cents for a list of denominations.

  Automatically detects the currency based on denomination names.
  """
  def calculate_total(denominations) do
    # Build a lookup map from all supported currencies
    denomination_values = build_denomination_lookup()

    Enum.reduce(denominations, 0, fn {id, count, _singular, _plural}, acc ->
      case Map.get(denomination_values, id) do
        nil ->
          raise "Unknown denomination: #{id}"

        value ->
          acc + value * count
      end
    end)
  end

  defp build_denomination_lookup do
    Currency.supported()
    |> Enum.flat_map(fn currency ->
      Currency.denominations(currency)
    end)
    |> Map.new(fn {id, value, _singular, _plural} -> {id, value} end)
  end

  @doc """
  Parses a formatted change string back into change items.

  Returns `{:ok, change_items}` or `{:error, reason}`.

  Each change item has the count (not value) in position 2.

  This is a test helper for verifying formatted output.
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
      Currency.supported()
      |> Enum.flat_map(fn currency ->
        Currency.denominations(currency)
      end)

    case Enum.find(denominations, fn {denom_id, _value, _singular, _plural} -> denom_id == id end) do
      nil -> :error
      denom -> {:ok, denom}
    end
  end
end
