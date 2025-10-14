defmodule CashRegister.FormatterTest do
  use ExUnit.Case, async: true

  alias CashRegister.Formatter

  describe "format/1" do
    test "formats multiple denominations" do
      assert Formatter.format([
               {"quarter", 3, "quarter", "quarters"},
               {"dime", 1, "dime", "dimes"},
               {"penny", 3, "penny", "pennies"}
             ]) ==
               "3 quarters,1 dime,3 pennies"
    end

    test "formats single dollar" do
      assert Formatter.format([{"dollar", 1, "dollar", "dollars"}]) == "1 dollar"
    end

    test "formats multiple pennies" do
      assert Formatter.format([{"penny", 2, "penny", "pennies"}]) == "2 pennies"
    end

    test "formats single nickel" do
      assert Formatter.format([{"nickel", 1, "nickel", "nickels"}]) == "1 nickel"
    end

    test "formats empty list as no change" do
      assert Formatter.format([]) == "no change"
    end
  end
end
