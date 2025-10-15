defmodule CashRegister.Strategies.GreedyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Strategies.Greedy

  describe "calculate/2" do
    test "calculates change using greedy algorithm" do
      assert {:ok,
              [
                {"quarter", 3, "quarter", "quarters"},
                {"dime", 1, "dime", "dimes"},
                {"penny", 3, "penny", "pennies"}
              ]} = Greedy.calculate(88)
    end

    test "returns empty list for zero change" do
      assert {:ok, []} = Greedy.calculate(0)
    end

    test "handles single denomination" do
      assert {:ok, [{"dollar", 1, "dollar", "dollars"}]} = Greedy.calculate(100)
    end

    test "handles all pennies" do
      assert {:ok, [{"penny", 3, "penny", "pennies"}]} = Greedy.calculate(3)
    end

    test "returns error when exact change cannot be made" do
      denominations_without_penny = [
        {"dollar", 100, "dollar", "dollars"},
        {"half_dollar", 50, "half-dollar", "half-dollars"},
        {"quarter", 25, "quarter", "quarters"},
        {"dime", 10, "dime", "dimes"},
        {"nickel", 5, "nickel", "nickels"}
      ]

      assert {:error, {:cannot_make_exact_change, %{remaining: 2, change_cents: 167}}} =
               Greedy.calculate(167, denominations: denominations_without_penny)
    end

    test "returns error for single cent when no penny denomination" do
      denominations_without_penny = [
        {"nickel", 5, "nickel", "nickels"}
      ]

      assert {:error, {:cannot_make_exact_change, %{remaining: 1, change_cents: 1}}} =
               Greedy.calculate(1, denominations: denominations_without_penny)
    end
  end
end
