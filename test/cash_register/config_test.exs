defmodule CashRegister.ConfigTest do
  use ExUnit.Case, async: true

  alias CashRegister.Config

  describe "change_strategy/2 with default divisor" do
    test "returns Randomized for values divisible by 3" do
      assert {:ok, CashRegister.Strategies.Randomized} = Config.change_strategy(99)
      assert {:ok, CashRegister.Strategies.Randomized} = Config.change_strategy(3)
      assert {:ok, CashRegister.Strategies.Randomized} = Config.change_strategy(300)
    end

    test "returns Greedy for values not divisible by 3" do
      assert {:ok, CashRegister.Strategies.Greedy} = Config.change_strategy(88)
      assert {:ok, CashRegister.Strategies.Greedy} = Config.change_strategy(100)
      assert {:ok, CashRegister.Strategies.Greedy} = Config.change_strategy(1)
    end
  end

  describe "change_strategy/2 with custom divisor" do
    test "accepts custom divisor via opts" do
      assert {:ok, CashRegister.Strategies.Randomized} = Config.change_strategy(100, divisor: 5)
      assert {:ok, CashRegister.Strategies.Greedy} = Config.change_strategy(88, divisor: 5)
    end
  end

  describe "change_strategy/2 with invalid divisor" do
    test "returns error for zero divisor" do
      assert {:error, message} = Config.change_strategy(100, divisor: 0)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: 0"
    end

    test "returns error for negative divisor" do
      assert {:error, message} = Config.change_strategy(100, divisor: -5)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: -5"
    end

    test "returns error for non-integer divisor" do
      assert {:error, message} = Config.change_strategy(100, divisor: 3.5)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: 3.5"
    end

    test "returns error for non-numeric divisor" do
      assert {:error, message} = Config.change_strategy(100, divisor: "three")
      assert message =~ "divisor must be a positive integer"
      assert message =~ ~s(got: "three")
    end
  end
end
