# Architecture

The Cash Register system uses a Strategy pattern with an extensible rules pipeline for calculating change.

## Strategies

- **Greedy**: Standard largest-first denomination algorithm (default)
- **Randomized**: Shuffles denominations before applying greedy (when change divisible by configured divisor)

## Components

- **Parser** - Converts CSV input to integers (cents using Decimal library)
- **Calculator** - Orchestrates strategy selection and change calculation
- **StrategyRules** - Extensible rules pipeline for strategy selection
- **Currency** - Provides denomination sets for USD and EUR
- **Formatter** - Converts denominations to readable strings

## Special Behavior

When change is divisible by the configured divisor (default: 3), the system randomizes the denomination order before calculating. This produces valid but varied results.

**Example:**

- Owed: $1.01, Paid: $2.00 -> Change: $0.99 (99 cents)
- 99 / 3 = 33
- Output varies: "9 dimes,1 nickel,4 pennies" or "3 quarters,2 dimes,4 pennies"

This behavior can be controlled using the `divisor` option.

## Extensible Rules Pipeline

The rules system allows custom logic for strategy selection. Rules are functions that take the change amount and options, returning either `{:ok, strategy_module}` or `nil`.

### Custom Rule Example

```elixir
# Define a custom rule
large_amount_rule = fn cents, _opts ->
  if cents > 10_000, do: {:ok, CashRegister.Strategies.Randomized}
end

# Use custom rules
CashRegister.process_transaction(15_000, 20_000, strategy_rules: [large_amount_rule])
```

Rules are evaluated in order, and the first matching rule determines the strategy. If no rules match, the Greedy strategy is used.

## Precision

All amounts are stored as integer cents using the Decimal library to avoid floating-point precision errors.
