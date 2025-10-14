defmodule CashRegisterTest do
  use ExUnit.Case, async: true

  import CashRegister.DenominationHelpers

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

      assert {:ok, denominations} = parse_change_result(result)

      assert_correct_total(denominations, 99)
    end

    test "accepts custom divisor option" do
      # 90 is divisible by 5, so with divisor: 5 it uses Randomized
      assert {:ok, result} = CashRegister.process_transaction(10, 100, divisor: 5)

      assert {:ok, denominations} = parse_change_result(result)

      assert_correct_total(denominations, 90)
    end
  end

  describe "process_file/2" do
    @describetag :tmp_dir

    test "processes valid file with multiple transactions", %{tmp_dir: tmp_dir} do
      file_path = Path.join(tmp_dir, "transactions.txt")
      content = "2.12,3.00\n1.00,1.00\n0.50,1.00"

      File.write!(file_path, content)

      results = CashRegister.process_file(file_path)

      assert is_list(results)
      assert length(results) == 3

      assert "3 quarters,1 dime,3 pennies" = Enum.at(results, 0)
      assert "no change" = Enum.at(results, 1)
      assert "2 quarters" = Enum.at(results, 2)
    end

    test "returns error for nonexistent file" do
      assert {:error, message} = CashRegister.process_file("nonexistent_file.txt")
      assert message =~ "cannot read file"
      assert message =~ "nonexistent_file.txt"
    end

    test "processes empty file", %{tmp_dir: tmp_dir} do
      file_path = Path.join(tmp_dir, "empty.txt")

      File.write!(file_path, "")

      results = CashRegister.process_file(file_path)

      assert results == []
    end

    test "returns first error for file with invalid line", %{tmp_dir: tmp_dir} do
      file_path = Path.join(tmp_dir, "mixed.txt")
      content = "2.12,3.00\ninvalid,line\n1.00,1.00"

      File.write!(file_path, content)

      result = CashRegister.process_file(file_path)

      # Should return the first parse error, not a list
      assert {:error, message} = result
      assert message =~ "invalid"
    end

    test "accepts custom divisor option for file processing", %{tmp_dir: tmp_dir} do
      file_path = Path.join(tmp_dir, "divisor.txt")
      content = "0.10,1.00"

      File.write!(file_path, content)

      # 90 cents is divisible by 5, should use randomized strategy
      results = CashRegister.process_file(file_path, divisor: 5)

      assert is_list(results)
      assert [result] = results

      # Should still total to 90 cents
      assert {:ok, denominations} = parse_change_result(result)
      assert_correct_total(denominations, 90)
    end
  end
end
