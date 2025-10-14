defmodule CashRegister.Strategies.RandomizedTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Strategies.Randomized

  describe "calculate/2" do
    test "produces valid change that sums correctly" do
      change_cents = 88
      result = Randomized.calculate(change_cents)

      assert_correct_total(result, change_cents)
    end

    test "returns empty list for zero change" do
      assert [] = Randomized.calculate(0)
    end
  end

  describe "calculate/2 with random_seed" do
    test "produces deterministic results with same seed" do
      change_cents = 99

      result1 = Randomized.calculate(change_cents, random_seed: 42)
      result2 = Randomized.calculate(change_cents, random_seed: 42)

      assert result1 == result2
      assert_correct_total(result1, change_cents)
    end

    test "different seeds may produce different orderings" do
      change_cents = 99

      result1 = Randomized.calculate(change_cents, random_seed: 42)
      result2 = Randomized.calculate(change_cents, random_seed: 123)

      # Both should still be valid
      assert_correct_total(result1, change_cents)
      assert_correct_total(result2, change_cents)

      # Results should be lists (not empty for 99 cents)
      assert is_list(result1) and length(result1) > 0
      assert is_list(result2) and length(result2) > 0
    end

    test "seeded randomization still produces valid change" do
      change_cents = 67
      result = Randomized.calculate(change_cents, random_seed: 1)

      assert_correct_total(result, change_cents)
    end
  end
end
