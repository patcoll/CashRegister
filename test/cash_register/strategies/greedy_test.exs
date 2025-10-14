defmodule CashRegister.Strategies.GreedyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Strategies.Greedy

  describe "calculate/2" do
    test "calculates change using greedy algorithm" do
      assert [{"quarter", 3}, {"dime", 1}, {"penny", 3}] = Greedy.calculate(88)
    end

    test "returns empty list for zero change" do
      assert [] = Greedy.calculate(0)
    end

    test "handles single denomination" do
      assert [{"dollar", 1}] = Greedy.calculate(100)
    end

    test "handles all pennies" do
      assert [{"penny", 3}] = Greedy.calculate(3)
    end
  end
end
