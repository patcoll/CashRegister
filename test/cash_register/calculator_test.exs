defmodule CashRegister.CalculatorTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Calculator

  describe "calculate/3" do
    test "calculates change correctly" do
      assert {:ok, [{"quarter", 3}, {"dime", 1}, {"penny", 3}]} =
               Calculator.calculate(212, 300)
    end

    test "returns empty list for exact change" do
      assert {:ok, []} = Calculator.calculate(100, 100)
    end

    test "returns error for insufficient payment" do
      assert {:error, "insufficient payment: paid 200 cents < owed 300 cents"} =
               Calculator.calculate(300, 200)
    end

    test "returns error for negative amounts" do
      {:error, reason} = Calculator.calculate(-100, 200)
      assert reason =~ "must be non-negative"
    end

    test "accepts custom divisor option" do
      # 100 is divisible by 5, so uses Randomized strategy
      assert {:ok, result} = Calculator.calculate(10, 100, divisor: 5)

      # Just verify it returns valid change
      assert_correct_total(result, 90)
    end

    test "custom divisor that triggers Greedy" do
      # 88 is not divisible by 5, so uses Greedy
      assert {:ok, [{"quarter", 3}, {"dime", 1}, {"penny", 3}]} =
               Calculator.calculate(0, 88, divisor: 5)
    end

    test "calculates change with EUR currency" do
      # 100 cents change using EUR denominations
      assert {:ok, [{"euro", 1}]} = Calculator.calculate(0, 100, currency: "EUR")
    end

    test "calculates change with GBP currency" do
      # 50 cents change using GBP denominations
      assert {:ok, [{"pence_50", 1}]} = Calculator.calculate(0, 50, currency: "GBP")
    end

    test "calculates EUR change with randomized strategy" do
      # 99 cents is divisible by 3, triggers randomized strategy
      {:ok, result} = Calculator.calculate(0, 99, currency: "EUR")

      # Verify the total is correct regardless of strategy
      assert_correct_total(result, 99)
    end
  end
end
