# Architecture

The Cash Register system uses a Strategy pattern with an extensible rules pipeline for calculating change.

## Strategies

- **Greedy**: Standard largest-first denomination algorithm (default)
- **Randomized**: Shuffles denominations before applying greedy (when owed amount divisible by configured divisor)

## Components

- **Parser** - Converts CSV input to integers (cents using Decimal library)
- **Calculator** - Orchestrates strategy selection and change calculation
- **StrategyRules** - Extensible rules pipeline for strategy selection
- **Currency** - Provides denomination sets for USD and EUR
- **Formatter** - Converts denominations to readable strings

## Special Behavior

When the owed amount is divisible by the configured divisor (default: 3), the system randomizes the denomination order before calculating. This produces valid but varied results.

**Example:**

- Owed: $3.00, Paid: $4.00 -> Change: $1.00 (100 cents)
- Owed amount: $3.00 = 300 cents
- 300 / 3 = 100 (divisible by 3, so uses Randomized strategy)
- Output varies: "4 quarters" or "10 dimes" or "2 quarters,5 dimes"

This behavior can be controlled using the `divisor` option.

## Extensible Rules Pipeline

The rules system allows custom logic for strategy selection. Rules are functions that take a context map (with `:owed_cents`, `:paid_cents`, and `:change_cents`) and options, returning either `{:ok, strategy_module}` or `nil`.

### Custom Rule Example

```elixir
# Define a custom rule based on large change amounts
large_change_rule = fn context, _opts ->
  if context.change_cents > 10_000, do: {:ok, CashRegister.Strategies.Randomized}
end

# Or a rule based on the owed amount
large_purchase_rule = fn context, _opts ->
  if context.owed_cents > 50_000, do: {:ok, CashRegister.Strategies.Randomized}
end

# Use custom rules
CashRegister.process_transaction(15_000, 20_000, strategy_rules: [large_change_rule])
```

Rules are evaluated in order, and the first matching rule determines the strategy. If no rules match, the Greedy strategy is used.

## Precision

All amounts are stored as integer cents using the Decimal library to avoid floating-point precision errors.
