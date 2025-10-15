defmodule CashRegister.CurrencyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Currency

  describe "denominations/0" do
    test "returns 5 denominations" do
      {:ok, denoms} = Currency.denominations()
      assert length(denoms) == 5
    end

    test "first denomination is dollar" do
      {:ok, denoms} = Currency.denominations()
      assert hd(denoms) == {"dollar", 100, "dollar", "dollars"}
    end

    test "last denomination is penny" do
      {:ok, denoms} = Currency.denominations()
      assert List.last(denoms) == {"penny", 1, "penny", "pennies"}
    end
  end

  describe "denominations/1 with currency code" do
    test "returns USD denominations for USD currency code" do
      {:ok, denoms} = Currency.denominations("USD")
      assert length(denoms) == 5
      assert hd(denoms) == {"dollar", 100, "dollar", "dollars"}
    end

    test "returns EUR denominations for EUR currency code" do
      {:ok, denoms} = Currency.denominations("EUR")
      assert length(denoms) == 8
      assert hd(denoms) == {"euro_2", 200, "2-euro coin", "2-euro coins"}
      assert {"euro", 100, "euro", "euros"} in denoms
      assert List.last(denoms) == {"cent", 1, "cent", "cents"}
    end

    test "returns GBP denominations for GBP currency code" do
      {:ok, denoms} = Currency.denominations("GBP")
      assert length(denoms) == 8
      assert hd(denoms) == {"pound_2", 200, "2-pound coin", "2-pound coins"}
      assert {"pound", 100, "pound", "pounds"} in denoms
      assert List.last(denoms) == {"penny", 1, "penny", "pennies"}
    end

    test "returns error for unknown currency code" do
      assert {:error, {:unknown_currency, %{currency: "XXX"}}} = Currency.denominations("XXX")
    end
  end

  describe "resolve_denominations/1" do
    test "returns default USD denominations with empty opts" do
      {:ok, denoms} = Currency.resolve_denominations([])
      assert length(denoms) == 5
      assert hd(denoms) == {"dollar", 100, "dollar", "dollars"}
    end

    test "returns EUR denominations when currency option provided" do
      {:ok, denoms} = Currency.resolve_denominations(currency: "EUR")
      assert length(denoms) == 8
      assert hd(denoms) == {"euro_2", 200, "2-euro coin", "2-euro coins"}
    end

    test "returns GBP denominations when currency option provided" do
      {:ok, denoms} = Currency.resolve_denominations(currency: "GBP")
      assert length(denoms) == 8
      assert hd(denoms) == {"pound_2", 200, "2-pound coin", "2-pound coins"}
    end

    test "returns custom denominations when provided" do
      custom = [{"custom", 50}, {"other", 25}]
      {:ok, denoms} = Currency.resolve_denominations(denominations: custom)
      assert denoms == custom
    end

    test "custom denominations take priority over currency option" do
      custom = [{"custom", 50}]
      {:ok, denoms} = Currency.resolve_denominations(denominations: custom, currency: "EUR")
      assert denoms == custom
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
