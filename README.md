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
"3 quarters,1 dime,3 pennies"

iex> CashRegister.process_file("sample_input.txt")
["3 quarters,1 dime,3 pennies", "1 dollar", "1 quarter"]
```

## Usage

### Single Transaction

```elixir
CashRegister.process_transaction(212, 300)
# "3 quarters,1 dime,3 pennies"

CashRegister.process_transaction(100, 100)
# "no change"
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
# ** (ArgumentError) insufficient payment: paid 200 cents < owed 300 cents

CashRegister.process_transaction(-100, 200)
# ** (ArgumentError) amounts must be non-negative: owed=-100, paid=200
```

## Special Behavior

When change is divisible by 3, the system randomizes the denomination order before calculating. This produces valid but varied results.

**Example:**

- Owed: $1.01, Paid: $2.00 -> Change: $0.99 (99 cents)
- 99 / 3 = 33
- Output varies: "9 dimes,1 nickel,4 pennies" or "3 quarters,2 dimes,4 pennies"

Change the divisor at runtime:

```elixir
Application.put_env(:cash_register, :divisor, 5)
```

## How It Works

The system uses a Strategy pattern to select between two algorithms:

- **Greedy**: Standard largest-first denomination algorithm (default)
- **Randomized**: Shuffles denominations before applying greedy (when change divisible by configured divisor)

Components:

- `Parser` - Converts CSV input to integers (cents)
- `Calculator` - Selects strategy and calculates change
- `Formatter` - Converts denominations to readable strings
- `Config` - Provides denominations and strategy selection logic

All amounts are stored as integer cents to avoid floating-point errors.

## Testing

```bash
mix test                    # Run all tests (29 total)
mix test --trace            # Detailed output
mix test --cover            # Coverage report
```

Tests cover:

- Input parsing and validation
- Both calculation strategies
- Output formatting and pluralization
- Strategy selection logic
- Edge cases (exact change, negative amounts, invalid input)

## Code Quality

```bash
mix format                  # Format code
mix credo list --strict     # Static analysis
mix compile --warnings-as-errors
```

## Requirements

- Elixir ~> 1.18
- Erlang/OTP 27

## Dependencies

- `credo` ~> 1.7 (dev/test only)
