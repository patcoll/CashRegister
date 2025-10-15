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

  describe "process_file_and_output/3" do
    @describetag :tmp_dir

    test "writes formatted output to file", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "input.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      input_content = "2.12,3.00\n4.87,5.00"
      File.write!(input_path, input_content)

      assert :ok = CashRegister.process_file_and_output(input_path, output_path)

      assert {:ok, output_content} = File.read(output_path)
      lines = String.split(output_content, "\n", trim: true)

      assert length(lines) == 2
      assert "3 quarters,1 dime,3 pennies" = Enum.at(lines, 0)
      assert "1 dime,3 pennies" = Enum.at(lines, 1)
    end

    test "returns error for nonexistent input file", %{tmp_dir: tmp_dir} do
      output_path = Path.join(tmp_dir, "output.txt")

      assert {:error, message} =
               CashRegister.process_file_and_output("nonexistent.txt", output_path)

      assert message =~ "cannot read file"
      assert message =~ "nonexistent.txt"

      refute File.exists?(output_path)
    end

    test "returns error for invalid input format", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "invalid.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "invalid,data,format")

      assert {:error, message} =
               CashRegister.process_file_and_output(input_path, output_path)

      assert message =~ "invalid"

      refute File.exists?(output_path)
    end

    test "returns error for insufficient payment", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "insufficient.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "5.00,3.00")

      assert {:error, message} =
               CashRegister.process_file_and_output(input_path, output_path)

      assert message =~ "insufficient payment"

      refute File.exists?(output_path)
    end

    test "handles empty input file", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "empty.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "")

      assert :ok = CashRegister.process_file_and_output(input_path, output_path)

      assert {:ok, output_content} = File.read(output_path)
      assert output_content == ""
    end

    test "overwrites existing output file", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "input.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "1.00,2.00")
      File.write!(output_path, "old content that should be replaced")

      assert :ok = CashRegister.process_file_and_output(input_path, output_path)

      assert {:ok, output_content} = File.read(output_path)
      assert output_content == "1 dollar"
    end

    test "accepts custom divisor option", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "divisor.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "0.10,1.00")

      assert :ok = CashRegister.process_file_and_output(input_path, output_path, divisor: 5)

      assert {:ok, output_content} = File.read(output_path)
      assert {:ok, denominations} = parse_change_result(output_content)
      assert_correct_total(denominations, 90)
    end

    test "accepts custom currency option", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "euro.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      File.write!(input_path, "1.00,2.00")

      assert :ok = CashRegister.process_file_and_output(input_path, output_path, currency: "EUR")

      assert {:ok, output_content} = File.read(output_path)
      assert output_content == "1 euro"
    end

    test "returns error when output directory does not exist", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "input.txt")
      output_path = Path.join([tmp_dir, "nonexistent", "output.txt"])

      File.write!(input_path, "1.00,2.00")

      assert {:error, message} = CashRegister.process_file_and_output(input_path, output_path)

      assert message =~ "cannot write file"
      assert message =~ output_path
    end

    test "handles multiple transactions correctly", %{tmp_dir: tmp_dir} do
      input_path = Path.join(tmp_dir, "multiple.txt")
      output_path = Path.join(tmp_dir, "output.txt")

      input_content = """
      2.12,3.00
      1.00,1.00
      0.50,1.00
      5.00,10.00
      """

      File.write!(input_path, input_content)

      assert :ok = CashRegister.process_file_and_output(input_path, output_path)

      assert {:ok, output_content} = File.read(output_path)
      lines = String.split(output_content, "\n", trim: true)

      assert length(lines) == 4
      assert "3 quarters,1 dime,3 pennies" = Enum.at(lines, 0)
      assert "no change" = Enum.at(lines, 1)
      assert "2 quarters" = Enum.at(lines, 2)
      assert "5 dollars" = Enum.at(lines, 3)
    end
  end
end
