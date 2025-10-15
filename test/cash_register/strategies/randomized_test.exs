defmodule CashRegister.Strategies.RandomizedTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Strategies.Randomized

  describe "calculate/2" do
    test "produces valid change that sums correctly" do
      change_cents = 88
      {:ok, result} = Randomized.calculate(change_cents)

      assert_correct_total(result, change_cents)
    end

    test "returns empty list for zero change" do
      assert {:ok, []} = Randomized.calculate(0)
    end

    test "returns error when exact change cannot be made" do
      denominations_without_penny = [
        {"dollar", 100, "dollar", "dollars"},
        {"half_dollar", 50, "half-dollar", "half-dollars"},
        {"quarter", 25, "quarter", "quarters"},
        {"dime", 10, "dime", "dimes"},
        {"nickel", 5, "nickel", "nickels"}
      ]

      assert {:error, message} =
               Randomized.calculate(167, denominations: denominations_without_penny)

      assert message =~ "cannot make exact change"
      assert message =~ "2 cents remaining"
    end

    test "returns error for single cent when no penny denomination" do
      denominations_without_penny = [
        {"nickel", 5, "nickel", "nickels"}
      ]

      assert {:error, message} =
               Randomized.calculate(1, denominations: denominations_without_penny)

      assert message =~ "cannot make exact change"
      assert message =~ "1 cents remaining"
    end
  end

  describe "calculate/2 with random_seed" do
    test "produces deterministic results with same seed" do
      change_cents = 99

      {:ok, result1} = Randomized.calculate(change_cents, random_seed: 42)
      {:ok, result2} = Randomized.calculate(change_cents, random_seed: 42)

      assert result1 == result2
      assert_correct_total(result1, change_cents)
    end

    test "different seeds may produce different orderings" do
      change_cents = 99

      {:ok, result1} = Randomized.calculate(change_cents, random_seed: 42)
      {:ok, result2} = Randomized.calculate(change_cents, random_seed: 123)

      # Both should still be valid
      assert_correct_total(result1, change_cents)
      assert_correct_total(result2, change_cents)

      # Results should be lists (not empty for 99 cents)
      assert is_list(result1) and length(result1) > 0
      assert is_list(result2) and length(result2) > 0
    end

    test "seeded randomization still produces valid change" do
      change_cents = 67
      {:ok, result} = Randomized.calculate(change_cents, random_seed: 1)

      assert_correct_total(result, change_cents)
    end

    test "seeded calculation does not pollute global random state" do
      # Establish a baseline random state
      :rand.uniform(1_000_000)

      # Save the state before our seeded calculation
      state_before = :rand.export_seed()

      # Call randomized calculation with a seed
      {:ok, _result} = Randomized.calculate(99, random_seed: 42)

      # Get the state after our calculation
      state_after = :rand.export_seed()

      # If the random state was properly restored, both states should be identical
      assert state_before == state_after,
             "Random state was polluted by seeded calculation"
    end
  end
end
