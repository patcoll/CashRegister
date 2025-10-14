defmodule CashRegister.DenominationHelpers do
  @moduledoc """
  Shared test helpers for working with denomination lists.
  """

  alias CashRegister.Config

  @doc """
  Asserts that a list of denominations sums to the expected total in cents.
  """
  defmacro assert_correct_total(denominations, expected_cents) do
    quote do
      total = CashRegister.DenominationHelpers.calculate_total(unquote(denominations))
      assert total == unquote(expected_cents)
    end
  end

  @doc """
  Calculates the total value in cents for a list of denominations.
  """
  def calculate_total(denominations) do
    Enum.reduce(denominations, 0, fn {name, count}, acc ->
      value =
        Config.denominations()
        |> Enum.find(fn {n, _} -> n == name end)
        |> elem(1)

      acc + value * count
    end)
  end
end
