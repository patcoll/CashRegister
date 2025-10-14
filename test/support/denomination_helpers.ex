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

    Enum.reduce(denominations, 0, fn {name, count}, acc ->
      case Map.get(denomination_values, name) do
        nil ->
          raise "Unknown denomination: #{name}"

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
    |> Map.new()
  end
end
