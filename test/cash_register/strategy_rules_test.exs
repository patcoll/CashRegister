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
      assert {:error, {:invalid_divisor, %{divisor: 0}}} =
               StrategyRules.select_strategy(100, divisor: 0)
    end

    test "returns error for negative divisor" do
      assert {:error, {:invalid_divisor, %{divisor: -5}}} =
               StrategyRules.select_strategy(100, divisor: -5)
    end

    test "returns error for non-integer divisor" do
      assert {:error, {:invalid_divisor, %{divisor: 3.5}}} =
               StrategyRules.select_strategy(100, divisor: 3.5)
    end

    test "returns error for non-numeric divisor" do
      assert {:error, {:invalid_divisor, %{divisor: "three"}}} =
               StrategyRules.select_strategy(100, divisor: "three")
    end
  end

  describe "select_strategy/2 with custom rules" do
    test "uses custom rule that always matches (with metadata)" do
      always_randomized = fn _cents, _opts -> {:ok, {Randomized, %{rule: :always}}} end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(100, strategy_rules: [always_randomized])

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(1, strategy_rules: [always_randomized])
    end

    test "uses custom rule without metadata" do
      simple_rule = fn _cents, _opts -> {:ok, Randomized} end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(100, strategy_rules: [simple_rule])

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(1, strategy_rules: [simple_rule])
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

  describe "divisor_match/2" do
    test "returns {:ok, {Randomized, metadata}} for values divisible by default divisor (3)" do
      assert {:ok, {Randomized, metadata}} = StrategyRules.divisor_match(99, [])
      assert metadata.divisor == 3
      assert metadata.rule == :divisor_match

      assert {:ok, {Randomized, metadata}} = StrategyRules.divisor_match(3, [])
      assert metadata.divisor == 3

      assert {:ok, {Randomized, metadata}} = StrategyRules.divisor_match(300, [])
      assert metadata.divisor == 3
    end

    test "returns nil for values not divisible by default divisor (3)" do
      assert nil == StrategyRules.divisor_match(88, [])
      assert nil == StrategyRules.divisor_match(100, [])
      assert nil == StrategyRules.divisor_match(1, [])
    end

    test "respects custom divisor from opts" do
      assert {:ok, {Randomized, metadata}} = StrategyRules.divisor_match(100, divisor: 5)
      assert metadata.divisor == 5
      assert metadata.rule == :divisor_match

      assert nil == StrategyRules.divisor_match(88, divisor: 5)
    end

    test "returns error for invalid divisor" do
      assert {:error, {:invalid_divisor, %{divisor: 0}}} =
               StrategyRules.divisor_match(100, divisor: 0)
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

      # Test that the rule behaves like divisor_match
      assert {:ok, {Randomized, metadata}} = rule.(99, [])
      assert metadata.divisor == 3
      assert nil == rule.(100, [])
    end
  end

  describe "select_strategy/2 telemetry" do
    setup do
      # Attach telemetry handler for testing
      :telemetry.attach(
        "test-strategy-selection",
        [:cash_register, :strategy, :selected],
        fn event_name, measurements, metadata, pid ->
          send(pid, {:telemetry_event, event_name, measurements, metadata})
        end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-strategy-selection") end)

      :ok
    end

    test "emits telemetry event when divisor rule matches" do
      assert {:ok, Randomized} = StrategyRules.select_strategy(99)

      assert_receive {:telemetry_event, [:cash_register, :strategy, :selected], measurements,
                      metadata}

      assert measurements.change_cents == 99

      assert metadata.strategy == "CashRegister.Strategies.Randomized"
      assert metadata.divisor == 3
      assert metadata.rule == :divisor_match
      assert metadata.change_cents == 99
    end

    test "emits telemetry event with custom divisor" do
      assert {:ok, Randomized} = StrategyRules.select_strategy(100, divisor: 5)

      assert_receive {:telemetry_event, [:cash_register, :strategy, :selected], _measurements,
                      metadata}

      assert metadata.strategy == "CashRegister.Strategies.Randomized"
      assert metadata.divisor == 5
      assert metadata.rule == :divisor_match
    end

    test "emits telemetry event when falling back to Greedy" do
      assert {:ok, Greedy} = StrategyRules.select_strategy(100)

      assert_receive {:telemetry_event, [:cash_register, :strategy, :selected], measurements,
                      metadata}

      assert measurements.change_cents == 100

      assert metadata.strategy == "CashRegister.Strategies.Greedy"
      assert metadata.divisor == 3
      assert metadata.rule == :default_fallback
      assert metadata.change_cents == 100
    end

    test "emits telemetry with custom rule metadata" do
      custom_rule = fn cents, _opts ->
        if cents > 5_000,
          do: {:ok, {Randomized, %{rule: :large_amount, threshold: 5_000, reason: "big sale"}}}
      end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(10_000, strategy_rules: [custom_rule])

      assert_receive {:telemetry_event, [:cash_register, :strategy, :selected], _measurements,
                      metadata}

      # Custom rule metadata should be merged
      assert metadata.rule == :large_amount
      assert metadata.threshold == 5_000
      assert metadata.reason == "big sale"
      assert metadata.strategy == "CashRegister.Strategies.Randomized"
    end

    test "emits telemetry for rules without metadata" do
      simple_rule = fn cents, _opts ->
        if cents > 1_000, do: {:ok, Randomized}
      end

      assert {:ok, Randomized} =
               StrategyRules.select_strategy(5_000, strategy_rules: [simple_rule])

      assert_receive {:telemetry_event, [:cash_register, :strategy, :selected], _measurements,
                      metadata}

      # Should have default telemetry metadata even without rule metadata
      assert metadata.strategy == "CashRegister.Strategies.Randomized"
      assert metadata.divisor == 3
      assert metadata.change_cents == 5_000
    end

    test "does not emit telemetry on error" do
      assert {:error, _} = StrategyRules.select_strategy(100, divisor: 0)

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end
end
