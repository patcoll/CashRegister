defmodule CashRegisterTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

  alias CashRegister.Parser

  describe "process_transaction/3" do
    test "processes single transaction" do
      assert {:ok, "3 quarters,1 dime,3 pennies"} = CashRegister.process_transaction(212, 300)
    end

    test "returns error for insufficient payment" do
      assert {:error, "insufficient payment: paid 200 cents < owed 300 cents"} =
               CashRegister.process_transaction(300, 200)
    end

    test "processes exact change transaction" do
      assert {:ok, "no change"} = CashRegister.process_transaction(100, 100)
    end

    test "processes transaction with divisible-by-3 change" do
      assert {:ok, result} = CashRegister.process_transaction(101, 200)

      assert {:ok, denominations} = Parser.parse_change_result(result)

      assert_correct_total(denominations, 99)
    end

    test "accepts custom divisor option" do
      # 90 is divisible by 5, so with divisor: 5 it uses Randomized
      assert {:ok, result} = CashRegister.process_transaction(10, 100, divisor: 5)

      assert {:ok, denominations} = Parser.parse_change_result(result)

      assert_correct_total(denominations, 90)
    end
  end
end
