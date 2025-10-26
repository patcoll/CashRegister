defmodule CashRegister.CurrencyTest do
  use ExUnit.Case, async: true

  alias CashRegister.Currency

  describe "denominations/0" do
    test "returns 10 denominations" do
      {:ok, denoms} = Currency.denominations()
      assert length(denoms) == 10
    end

    test "first denomination is hundred-dollar bill" do
      {:ok, denoms} = Currency.denominations()

      assert hd(denoms) ==
               {"hundred_dollar", 10_000, "hundred-dollar bill", "hundred-dollar bills"}
    end

    test "last denomination is penny" do
      {:ok, denoms} = Currency.denominations()
      assert List.last(denoms) == {"penny", 1, "penny", "pennies"}
    end
  end

  describe "denominations/1 with currency code" do
    test "returns USD denominations for USD currency code" do
      {:ok, denoms} = Currency.denominations("USD")
      assert length(denoms) == 10

      assert hd(denoms) ==
               {"hundred_dollar", 10_000, "hundred-dollar bill", "hundred-dollar bills"}
    end

    test "returns EUR denominations for EUR currency code" do
      {:ok, denoms} = Currency.denominations("EUR")
      assert length(denoms) == 15
      assert hd(denoms) == {"euro_500", 50_000, "500-euro bill", "500-euro bills"}
      assert {"euro", 100, "euro", "euros"} in denoms
      assert List.last(denoms) == {"cent", 1, "cent", "cents"}
    end

    test "returns error for unknown currency code" do
      assert {:error, {:unknown_currency, %{currency: "XXX"}}} = Currency.denominations("XXX")
    end
  end

  describe "resolve_denominations/1" do
    test "returns default USD denominations with empty opts" do
      {:ok, denoms} = Currency.resolve_denominations([])
      assert length(denoms) == 10

      assert hd(denoms) ==
               {"hundred_dollar", 10_000, "hundred-dollar bill", "hundred-dollar bills"}
    end

    test "returns EUR denominations when currency option provided" do
      {:ok, denoms} = Currency.resolve_denominations(currency: "EUR")
      assert length(denoms) == 15
      assert hd(denoms) == {"euro_500", 50_000, "500-euro bill", "500-euro bills"}
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
      assert length(currencies) == 2
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
      refute Currency.info("XXX")
    end
  end

  describe "default/0" do
    test "returns USD as default" do
      assert Currency.default() == "USD"
    end
  end
end
