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

  describe "parse_line/1 - error cases" do
    test "returns error for invalid format" do
      assert {:error, "invalid line format: invalid"} = Parser.parse_line("invalid")
    end

    test "returns error for negative amounts" do
      assert {:error, _reason} = Parser.parse_line("-1.00,2.00")
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
      assert {:ok, [{"quarter", 3}, {"dime", 1}, {"penny", 3}]} =
               Parser.parse_change_result("3 quarters,1 dime,3 pennies")
    end

    test "parses single dollar" do
      assert {:ok, [{"dollar", 1}]} = Parser.parse_change_result("1 dollar")
    end

    test "parses multiple pennies" do
      assert {:ok, [{"penny", 2}]} = Parser.parse_change_result("2 pennies")
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
