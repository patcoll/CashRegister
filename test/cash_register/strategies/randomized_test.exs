defmodule CashRegister.Strategies.RandomizedTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Strategies.Randomized

  describe "calculate/1" do
    test "produces valid change that sums correctly" do
      change_cents = 88
      result = Randomized.calculate(change_cents)

      assert_correct_total(result, change_cents)
    end

    test "returns empty list for zero change" do
      assert [] = Randomized.calculate(0)
    end
  end
end
