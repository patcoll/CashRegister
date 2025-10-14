# Cash Register

Calculates change for cash transactions using smart denomination strategies.

## Quick Start

```bash
mix deps.get
mix test
```

```elixir
iex -S mix

iex> CashRegister.process_transaction(212, 300)
{:ok, "3 quarters,1 dime,3 pennies"}

iex> CashRegister.process_file("sample_input.txt")
[
  {:ok, "3 quarters,1 dime,3 pennies"},
  {:ok, "1 dollar"},
  {:ok, "1 quarter"},
  {:ok, "5 dollars"},
  {:ok, "3 quarters,2 dimes,4 pennies"}
]
```

## Usage

### Single Transaction

```elixir
CashRegister.process_transaction(212, 300)
# {:ok, "3 quarters,1 dime,3 pennies"}

CashRegister.process_transaction(100, 100)
# {:ok, "no change"}
```

### File Processing

Input file (comma-separated owed,paid amounts):

```
2.12,3.00
1.00,2.00
0.75,1.00
```

```elixir
CashRegister.process_file("sample_input.txt")
```

### Errors

```elixir
CashRegister.process_transaction(300, 200)
# {:error, "insufficient payment: paid 200 cents < owed 300 cents"}

CashRegister.process_transaction(-100, 200)
# {:error, "amounts must be non-negative: owed=-100, paid=200"}
```

## Special Behavior

When change is divisible by 3, the system randomizes the denomination order before calculating. This produces valid but varied results.

**Example:**

- Owed: $1.01, Paid: $2.00 -> Change: $0.99 (99 cents)
- 99 / 3 = 33
- Output varies: "9 dimes,1 nickel,4 pennies" or "3 quarters,2 dimes,4 pennies"

### Custom Divisor

Change the divisor using options:

```elixir
# Use divisor of 5 instead of 3
CashRegister.process_transaction(212, 300, divisor: 5)

# Process file with custom divisor
CashRegister.process_file("sample_input.txt", divisor: 10)
```

### International Currency Support

Support for EUR and GBP currencies:

```elixir
# Use Euro denominations
CashRegister.process_transaction(212, 300, currency: "EUR")
# {:ok, "1 euro,1 10-cent coin,2 cents"}

# Use British Pound denominations
CashRegister.process_transaction(212, 300, currency: "GBP")
# {:ok, "50-pence coin,2 20-pence coins,2 5-pence coins,8 pennies"}
```

## How It Works

The system uses a Strategy pattern with an extensible rules pipeline:

### Strategies

- **Greedy**: Standard largest-first denomination algorithm (default)
- **Randomized**: Shuffles denominations before applying greedy (when change divisible by configured divisor)

### Components

- `Parser` - Converts CSV input to integers (cents using Decimal library)
- `Calculator` - Orchestrates strategy selection and change calculation
- `StrategyRules` - Extensible rules pipeline for strategy selection
- `Currency` - Provides denomination sets for USD, EUR, and GBP
- `Formatter` - Converts denominations to readable strings

### Extensible Rules Pipeline

The rules system allows custom logic for strategy selection:

```elixir
# Define a custom rule
large_amount_rule = fn cents, _opts ->
  if cents > 10_000, do: {:ok, CashRegister.Strategies.Randomized}
end

# Use custom rules
CashRegister.process_transaction(15_000, 20_000, strategy_rules: [large_amount_rule])
```

Rules are evaluated in order, and the first matching rule determines the strategy. If no rules match, the Greedy strategy is used.

All amounts are stored as integer cents using the Decimal library to avoid floating-point precision errors.

## Testing

```bash
mix test                    # Run all tests
mix test --trace            # Detailed output
mix test --cover            # Coverage report
```

Tests cover:

- Input parsing and validation with Decimal precision
- Both calculation strategies (Greedy and Randomized)
- Output formatting and pluralization
- Extensible rules pipeline and custom rules
- International currency support (USD, EUR, GBP)
- File processing with error handling
- Edge cases (exact change, negative amounts, invalid input, divisor validation)

## Code Quality

```bash
mix format                  # Format code
mix credo list --strict     # Static analysis
mix compile --warnings-as-errors
```

## Requirements

- Elixir ~> 1.18
- Erlang/OTP 27
