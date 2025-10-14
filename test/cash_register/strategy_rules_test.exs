defmodule CashRegister.StrategyRulesTest do
  use ExUnit.Case, async: true

  alias CashRegister.StrategyRules
  alias CashRegister.Strategies.{Greedy, Randomized}

  describe "select_strategy/2 with default divisor rule" do
    test "returns Randomized for values divisible by 3" do
      assert {:ok, Randomized} = StrategyRules.select_strategy(99)
      assert {:ok, Randomized} = StrategyRules.select_strategy(3)
      assert {:ok, Randomized} = StrategyRules.select_strategy(300)
    end

    test "returns Greedy for values not divisible by 3" do
      assert {:ok, Greedy} = StrategyRules.select_strategy(88)
      assert {:ok, Greedy} = StrategyRules.select_strategy(100)
      assert {:ok, Greedy} = StrategyRules.select_strategy(1)
    end

    test "returns Randomized for zero change (0 is divisible by any number)" do
      # Note: In production, Calculator.calculate/3 handles 0 change specially
      # and returns empty list without calling strategy selection.
      # This test verifies mathematical correctness: rem(0, 3) == 0 is true.
      assert {:ok, Randomized} = StrategyRules.select_strategy(0)
    end
  end

  describe "select_strategy/2 with custom divisor" do
    test "accepts custom divisor via opts" do
      assert {:ok, Randomized} = StrategyRules.select_strategy(100, divisor: 5)
      assert {:ok, Randomized} = StrategyRules.select_strategy(25, divisor: 5)
      assert {:ok, Greedy} = StrategyRules.select_strategy(88, divisor: 5)
    end

    test "uses divisor of 2" do
      assert {:ok, Randomized} = StrategyRules.select_strategy(100, divisor: 2)
      assert {:ok, Randomized} = StrategyRules.select_strategy(88, divisor: 2)
      assert {:ok, Greedy} = StrategyRules.select_strategy(99, divisor: 2)
    end
  end

  describe "select_strategy/2 with invalid divisor" do
    test "returns error for zero divisor" do
      assert {:error, message} = StrategyRules.select_strategy(100, divisor: 0)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: 0"
    end

    test "returns error for negative divisor" do
      assert {:error, message} = StrategyRules.select_strategy(100, divisor: -5)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: -5"
    end

    test "returns error for non-integer divisor" do
      assert {:error, message} = StrategyRules.select_strategy(100, divisor: 3.5)
      assert message =~ "divisor must be a positive integer"
      assert message =~ "got: 3.5"
    end

    test "returns error for non-numeric divisor" do
      assert {:error, message} = StrategyRules.select_strategy(100, divisor: "three")
      assert message =~ "divisor must be a positive integer"
      assert message =~ ~s(got: "three")
    end
  end

  describe "select_strategy/2 with custom rules" do
    test "uses custom rule that always matches" do
      always_randomized = fn _cents, _opts -> {:ok, Randomized} end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(100, strategy_rules: [always_randomized])

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(1, strategy_rules: [always_randomized])
    end

    test "uses custom rule that never matches" do
      never_matches = fn _cents, _opts -> nil end

      # Should fall back to Greedy
      assert {:ok, Greedy} = StrategyRules.select_strategy(100, strategy_rules: [never_matches])
      assert {:ok, Greedy} = StrategyRules.select_strategy(99, strategy_rules: [never_matches])
    end

    test "uses custom large amount rule" do
      # Rule: if change > 10_000 cents ($100), use Randomized
      large_amount_rule = fn cents, _opts ->
        if cents > 10_000, do: {:ok, Randomized}
      end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(15_000, strategy_rules: [large_amount_rule])

      assert {:ok, Greedy} =
               StrategyRules.select_strategy(5_000, strategy_rules: [large_amount_rule])
    end

    test "uses custom rule with configurable threshold" do
      # Rule that reads threshold from opts
      threshold_rule = fn cents, opts ->
        threshold = Keyword.get(opts, :large_threshold, 10_000)
        if cents > threshold, do: {:ok, Randomized}
      end

      # With default threshold (10_000)
      assert {:ok, Randomized} =
               StrategyRules.select_strategy(15_000, strategy_rules: [threshold_rule])

      assert {:ok, Greedy} =
               StrategyRules.select_strategy(5_000, strategy_rules: [threshold_rule])

      # With custom threshold (5_000)
      assert {:ok, Randomized} =
               StrategyRules.select_strategy(6_000,
                 strategy_rules: [threshold_rule],
                 large_threshold: 5_000
               )

      assert {:ok, Greedy} =
               StrategyRules.select_strategy(4_000,
                 strategy_rules: [threshold_rule],
                 large_threshold: 5_000
               )
    end
  end

  describe "select_strategy/2 with multiple rules" do
    test "evaluates rules in order, first match wins" do
      # First rule: if divisible by 2, use Randomized
      divisible_by_2 = fn cents, _opts ->
        if rem(cents, 2) == 0, do: {:ok, Randomized}
      end

      # Second rule: if divisible by 3, use Greedy (but won't be reached for 6)
      divisible_by_3 = fn cents, _opts ->
        if rem(cents, 3) == 0, do: {:ok, Greedy}
      end

      # 6 is divisible by both 2 and 3, but first rule wins
      assert {:ok, Randomized} =
               StrategyRules.select_strategy(6, strategy_rules: [divisible_by_2, divisible_by_3])

      # 9 is only divisible by 3, so second rule matches
      assert {:ok, Greedy} =
               StrategyRules.select_strategy(9, strategy_rules: [divisible_by_2, divisible_by_3])

      # 10 is only divisible by 2, so first rule matches
      assert {:ok, Randomized} =
               StrategyRules.select_strategy(10, strategy_rules: [divisible_by_2, divisible_by_3])
    end

    test "falls back to Greedy when no rules match" do
      divisible_by_7 = fn cents, _opts ->
        if rem(cents, 7) == 0, do: {:ok, Randomized}
      end

      divisible_by_11 = fn cents, _opts ->
        if rem(cents, 11) == 0, do: {:ok, Randomized}
      end

      # 100 is not divisible by 7 or 11, so falls back to Greedy
      assert {:ok, Greedy} =
               StrategyRules.select_strategy(100,
                 strategy_rules: [divisible_by_7, divisible_by_11]
               )
    end
  end

  describe "divisor_rule/2" do
    test "returns {:ok, Randomized} for values divisible by default divisor (3)" do
      assert {:ok, Randomized} == StrategyRules.divisor_rule(99, [])
      assert {:ok, Randomized} == StrategyRules.divisor_rule(3, [])
      assert {:ok, Randomized} == StrategyRules.divisor_rule(300, [])
    end

    test "returns nil for values not divisible by default divisor (3)" do
      assert nil == StrategyRules.divisor_rule(88, [])
      assert nil == StrategyRules.divisor_rule(100, [])
      assert nil == StrategyRules.divisor_rule(1, [])
    end

    test "respects custom divisor from opts" do
      assert {:ok, Randomized} == StrategyRules.divisor_rule(100, divisor: 5)
      assert nil == StrategyRules.divisor_rule(88, divisor: 5)
    end

    test "returns error for invalid divisor" do
      assert {:error, message} = StrategyRules.divisor_rule(100, divisor: 0)
      assert message =~ "divisor must be a positive integer"
    end
  end

  describe "default_rules/0" do
    test "returns a list containing the divisor rule" do
      rules = StrategyRules.default_rules()
      assert is_list(rules)
      assert length(rules) == 1
      assert is_function(hd(rules), 2)
    end

    test "default rules work correctly" do
      [rule] = StrategyRules.default_rules()

      # Test that the rule behaves like divisor_rule
      assert {:ok, Randomized} == rule.(99, [])
      assert nil == rule.(100, [])
    end
  end
end
