defmodule CashRegister.ParserTest do
  use ExUnit.Case, async: true

  alias CashRegister.Parser

  describe "parse_line/1 - US format" do
    test "parses US format with periods" do
      assert {:ok, {212, 300}} = Parser.parse_line("2.12,3.00")
      assert {:ok, {150, 200}} = Parser.parse_line("1.50,2.00")
      assert {:ok, {0, 100}} = Parser.parse_line("0.00,1.00")
    end
  end

  describe "parse_line/1 - international format" do
    test "parses international format with commas" do
      assert {:ok, {212, 300}} = Parser.parse_line("2,12,3,00")
      assert {:ok, {150, 200}} = Parser.parse_line("1,50,2,00")
      assert {:ok, {0, 100}} = Parser.parse_line("0,00,1,00")
    end
  end

  describe "parse_line/1 - edge cases for precision" do
    test "parses 0.29 correctly (problematic floating point case)" do
      assert {:ok, {29, 100}} = Parser.parse_line("0.29,1.00")
    end

    test "parses 1.5 correctly (single decimal digit with padding)" do
      assert {:ok, {150, 250}} = Parser.parse_line("1.5,2.5")
      assert {:ok, {130, 100}} = Parser.parse_line("1.3,1.0")
    end

    test "parses whole dollar amounts without decimal" do
      assert {:ok, {500, 1000}} = Parser.parse_line("5,10")
    end

    test "parses 2.99 correctly (edge of two decimal places)" do
      assert {:ok, {299, 100}} = Parser.parse_line("2.99,1.00")
    end

    test "parses zero amounts correctly" do
      assert {:ok, {0, 100}} = Parser.parse_line("0,1")
      assert {:ok, {0, 100}} = Parser.parse_line("0.0,1.0")
      assert {:ok, {0, 100}} = Parser.parse_line("0.00,1.00")
    end
  end

  describe "parse_line/1 - error cases" do
    test "returns error for invalid format" do
      assert {:error, "invalid line format: invalid"} = Parser.parse_line("invalid")
    end

    test "returns error for negative amounts with clear message" do
      assert {:error, reason} = Parser.parse_line("-1.00,2.00")
      assert reason =~ "must be non-negative"
      assert reason =~ "-1"
    end

    test "returns error for fractional cents (too many decimal places)" do
      assert {:error, reason} = Parser.parse_line("1.005,2.00")
      assert reason =~ "too many decimal places"
    end

    test "returns error for missing cents after decimal" do
      assert {:error, reason} = Parser.parse_line("1.,2.00")
      assert reason =~ "missing cents after decimal point"
    end

    test "returns error for multiple decimal points" do
      assert {:error, reason} = Parser.parse_line("1.2.3,2.00")
      assert reason =~ "multiple decimal points"
    end

    test "returns error for 3-element format" do
      assert {:error, "invalid line format: 1,00,2"} = Parser.parse_line("1,00,2")
    end

    test "returns error for 5-element format" do
      assert {:error, "invalid line format: 1,00,2,00,3"} = Parser.parse_line("1,00,2,00,3")
    end
  end

  describe "parse_lines/1" do
    test "parses US format lines" do
      assert [{212, 300}, {100, 200}] = Parser.parse_lines("2.12,3.00\n1.00,2.00\n")
    end

    test "parses international format lines" do
      assert [{212, 300}, {150, 200}] = Parser.parse_lines("2,12,3,00\n1,50,2,00\n")
    end

    test "parses mixed format lines" do
      assert [{212, 300}, {150, 200}] = Parser.parse_lines("2.12,3.00\n1,50,2,00\n")
    end

    test "raises ArgumentError for invalid line" do
      assert_raise ArgumentError, "invalid line format: invalid", fn ->
        Parser.parse_lines("2.12,3.00\ninvalid\n1.00,2.00")
      end
    end
  end

  describe "parse_change_result/1" do
    test "parses multiple denominations" do
      assert {:ok,
              [
                {"quarter", 3, "quarter", "quarters"},
                {"dime", 1, "dime", "dimes"},
                {"penny", 3, "penny", "pennies"}
              ]} = Parser.parse_change_result("3 quarters,1 dime,3 pennies")
    end

    test "parses single dollar" do
      assert {:ok, [{"dollar", 1, "dollar", "dollars"}]} =
               Parser.parse_change_result("1 dollar")
    end

    test "parses multiple pennies" do
      assert {:ok, [{"penny", 2, "penny", "pennies"}]} =
               Parser.parse_change_result("2 pennies")
    end

    test "parses 'no change'" do
      assert {:ok, []} = Parser.parse_change_result("no change")
    end

    test "parses empty string" do
      assert {:ok, []} = Parser.parse_change_result("")
    end

    test "returns error for invalid format" do
      assert {:error, "invalid change format: invalid format"} =
               Parser.parse_change_result("invalid format")
    end
  end
end
