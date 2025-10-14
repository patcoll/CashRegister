defmodule CashRegister.Strategies.GreedyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Strategies.Greedy

  describe "calculate/2" do
    test "calculates change using greedy algorithm" do
      assert [
               {"quarter", 3, "quarter", "quarters"},
               {"dime", 1, "dime", "dimes"},
               {"penny", 3, "penny", "pennies"}
             ] = Greedy.calculate(88)
    end

    test "returns empty list for zero change" do
      assert [] = Greedy.calculate(0)
    end

    test "handles single denomination" do
      assert [{"dollar", 1, "dollar", "dollars"}] = Greedy.calculate(100)
    end

    test "handles all pennies" do
      assert [{"penny", 3, "penny", "pennies"}] = Greedy.calculate(3)
    end
  end
end
