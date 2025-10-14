defmodule CashRegisterTest do
  use ExUnit.Case

  doctest CashRegister
  doctest CashRegister.Calculator
  doctest CashRegister.Config
  doctest CashRegister.Formatter
  doctest CashRegister.Parser

  alias CashRegister.Config
  alias CashRegister.Parser
  alias CashRegister.Strategies.{Greedy, Randomized}

  describe "Greedy change strategy" do
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

  describe "Randomized change strategy" do
    test "produces valid change that sums correctly" do
      change_cents = 88
      result = Randomized.calculate(change_cents)

      assert_correct_total(result, change_cents)
    end

    test "returns empty list for zero change" do
      assert [] = Randomized.calculate(0)
    end
  end

  describe "CashRegister transactions" do
    test "processes single transaction" do
      assert {:ok, "3 quarters,1 dime,3 pennies"} = CashRegister.process_transaction(212, 300)
    end

    test "processes exact change transaction" do
      assert {:ok, "no change"} = CashRegister.process_transaction(100, 100)
    end

    test "processes transaction with divisible-by-3 change" do
      assert {:ok, result} = CashRegister.process_transaction(101, 200)

      assert {:ok, denominations} = Parser.parse_change_result(result)

      assert_correct_total(denominations, 99)
    end
  end

  defp assert_correct_total(denominations, expected_cents) do
    total = calculate_total(denominations)
    assert total == expected_cents
  end

  defp calculate_total(denominations) do
    Enum.reduce(denominations, 0, fn {name, count}, acc ->
      value =
        Config.denominations()
        |> Enum.find(fn {n, _} -> n == name end)
        |> elem(1)

      acc + value * count
    end)
  end
end
