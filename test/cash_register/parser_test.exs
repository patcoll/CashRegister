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

    test "parses other problematic floating point amounts correctly" do
      assert {:ok, {19, 100}} = Parser.parse_line("0.19,1.00")
      assert {:ok, {39, 100}} = Parser.parse_line("0.39,1.00")
      assert {:ok, {1, 100}} = Parser.parse_line("0.01,1.00")
      assert {:ok, {99, 100}} = Parser.parse_line("0.99,1.00")
    end

    test "parses amounts with repeating decimal representations" do
      assert {:ok, {101, 200}} = Parser.parse_line("1.01,2.00")
      assert {:ok, {201, 300}} = Parser.parse_line("2.01,3.00")
      assert {:ok, {267, 300}} = Parser.parse_line("2.67,3.00")
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

    test "parses amount just under maximum limit ($99,999.99)" do
      assert {:ok, {9_999_999, 10_000_000}} = Parser.parse_line("99999.99,100000.00")
    end

    test "parses amount at maximum limit ($100,000.00)" do
      assert {:ok, {10_000_000, 10_000_000}} = Parser.parse_line("100000.00,100000.00")
    end

    test "returns error for amount just over maximum limit (100000.01)" do
      assert {:error, reason} = Parser.parse_line("100000.01,100000.01")
      assert reason =~ "amount exceeds maximum allowed"
      assert reason =~ "100000.00"
    end

    test "returns error for very large amount (1000000.00)" do
      assert {:error, reason} = Parser.parse_line("1000000.00,1.00")
      assert reason =~ "amount exceeds maximum allowed"
      assert reason =~ "100000.00"
    end
  end

  describe "parse_lines/1" do
    test "parses US format lines" do
      assert [
               {212, 300},
               {100, 200}
             ] = Parser.parse_lines("2.12,3.00\n1.00,2.00\n")
    end

    test "parses international format lines" do
      assert [
               {212, 300},
               {150, 200}
             ] = Parser.parse_lines("2,12,3,00\n1,50,2,00\n")
    end

    test "parses mixed format lines" do
      assert [
               {212, 300},
               {150, 200}
             ] = Parser.parse_lines("2.12,3.00\n1,50,2,00\n")
    end

    test "returns first error for invalid lines" do
      result = Parser.parse_lines("2.12,3.00\ninvalid\n1.00,2.00")

      assert {:error, "invalid line format: invalid"} = result
    end

    test "returns first error when all lines invalid" do
      result = Parser.parse_lines("invalid1\ninvalid2")

      assert {:error, "invalid line format: invalid1"} = result
    end

    test "returns empty list for empty content" do
      assert [] = Parser.parse_lines("")
    end
  end
end
