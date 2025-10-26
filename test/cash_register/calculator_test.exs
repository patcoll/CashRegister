defmodule CashRegister.CalculatorTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Calculator

  describe "calculate/3" do
    test "calculates change correctly" do
      assert {:ok,
              [
                {"quarter", 3, "quarter", "quarters"},
                {"dime", 1, "dime", "dimes"},
                {"penny", 3, "penny", "pennies"}
              ]} = Calculator.calculate(212, 300)
    end

    test "returns empty list for exact change" do
      assert {:ok, []} = Calculator.calculate(100, 100)
    end

    test "returns error for insufficient payment" do
      assert {:error, {:insufficient_payment, %{owed: 300, paid: 200}}} =
               Calculator.calculate(300, 200)
    end

    test "returns error for negative amounts" do
      assert {:error, {:negative_amount, %{owed: -100, paid: 200}}} =
               Calculator.calculate(-100, 200)
    end

    test "accepts custom divisor option" do
      # Owed amount (10) is divisible by 5, so uses Randomized strategy
      assert {:ok, result} = Calculator.calculate(10, 100, divisor: 5)

      assert_correct_total(result, 90)
    end

    test "custom divisor that triggers Greedy" do
      # Owed amount (88) is not divisible by 5, so uses Greedy
      assert {:ok,
              [
                {"quarter", 3, "quarter", "quarters"},
                {"dime", 1, "dime", "dimes"},
                {"penny", 3, "penny", "pennies"}
              ]} = Calculator.calculate(88, 176, divisor: 5)
    end

    test "calculates change with EUR currency" do
      # Owed amount (100) is not divisible by 3, so uses Greedy strategy
      # 100 cents change using EUR denominations
      assert {:ok, [{"euro", 1, "euro", "euros"}]} =
               Calculator.calculate(100, 200, currency: "EUR")
    end

    test "calculates EUR change with randomized strategy" do
      # Owed amount (0) is divisible by 3, triggers randomized strategy
      {:ok, result} = Calculator.calculate(0, 99, currency: "EUR")

      assert_correct_total(result, 99)
    end
  end
end
