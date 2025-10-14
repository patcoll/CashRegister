defmodule CashRegister.ConfigTest do
  use ExUnit.Case, async: true

  alias CashRegister.Config

  describe "denominations/0" do
    test "returns 5 denominations" do
      denoms = Config.denominations()
      assert length(denoms) == 5
    end

    test "first denomination is dollar" do
      assert hd(Config.denominations()) == {"dollar", 100}
    end

    test "last denomination is penny" do
      assert List.last(Config.denominations()) == {"penny", 1}
    end
  end

  describe "change_strategy/2 with default divisor" do
    test "returns Randomized for values divisible by 3" do
      assert Config.change_strategy(99) == CashRegister.Strategies.Randomized
      assert Config.change_strategy(3) == CashRegister.Strategies.Randomized
      assert Config.change_strategy(300) == CashRegister.Strategies.Randomized
    end

    test "returns Greedy for values not divisible by 3" do
      assert Config.change_strategy(88) == CashRegister.Strategies.Greedy
      assert Config.change_strategy(100) == CashRegister.Strategies.Greedy
      assert Config.change_strategy(1) == CashRegister.Strategies.Greedy
    end
  end

  describe "change_strategy/2 with custom divisor" do
    test "accepts custom divisor via opts" do
      assert Config.change_strategy(100, divisor: 5) == CashRegister.Strategies.Randomized
      assert Config.change_strategy(88, divisor: 5) == CashRegister.Strategies.Greedy
    end
  end
end
