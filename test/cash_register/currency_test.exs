defmodule CashRegister.CurrencyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Currency

  describe "denominations/0" do
    test "returns 5 denominations" do
      denoms = Currency.denominations()
      assert length(denoms) == 5
    end

    test "first denomination is dollar" do
      assert hd(Currency.denominations()) == {"dollar", 100}
    end

    test "last denomination is penny" do
      assert List.last(Currency.denominations()) == {"penny", 1}
    end
  end

  describe "denominations/1 with currency code" do
    test "returns USD denominations for USD currency code" do
      denoms = Currency.denominations("USD")
      assert length(denoms) == 5
      assert hd(denoms) == {"dollar", 100}
    end

    test "returns EUR denominations for EUR currency code" do
      denoms = Currency.denominations("EUR")
      assert length(denoms) == 8
      assert hd(denoms) == {"euro_2", 200}
      assert {"euro", 100} in denoms
      assert List.last(denoms) == {"cent", 1}
    end

    test "returns GBP denominations for GBP currency code" do
      denoms = Currency.denominations("GBP")
      assert length(denoms) == 8
      assert hd(denoms) == {"pound_2", 200}
      assert {"pound", 100} in denoms
      assert List.last(denoms) == {"penny", 1}
    end

    test "raises ArgumentError for unknown currency code" do
      assert_raise ArgumentError, ~r/unknown currency code/, fn ->
        Currency.denominations("XXX")
      end
    end
  end

  describe "supported/0" do
    test "returns list of supported currency codes" do
      currencies = Currency.supported()
      assert "USD" in currencies
      assert "EUR" in currencies
      assert "GBP" in currencies
      assert length(currencies) == 3
    end

    test "returns sorted list" do
      currencies = Currency.supported()
      assert currencies == Enum.sort(currencies)
    end
  end

  describe "info/1" do
    test "returns currency info for USD" do
      info = Currency.info("USD")
      assert info.name == "US Dollar"
      assert info.symbol == "$"
      assert is_list(info.denominations)
    end

    test "returns currency info for EUR" do
      info = Currency.info("EUR")
      assert info.name == "Euro"
      assert info.symbol == "€"
    end

    test "returns nil for unknown currency" do
      assert Currency.info("XXX") == nil
    end
  end

  describe "default/0" do
    test "returns USD as default" do
      assert Currency.default() == "USD"
    end
  end
end
