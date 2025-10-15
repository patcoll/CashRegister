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
  "3 quarters,1 dime,3 pennies",
  "1 dollar",
  "1 quarter",
  "5 dollars",
  "3 quarters,2 dimes,4 pennies"
]
```

## Command-Line Interface

Build the executable:

```bash
mix escript.build
```

This creates a standalone `cash_register` executable that can be run without Elixir installed.

### Basic Usage

```bash
./cash_register INPUT_FILE OUTPUT_FILE [OPTIONS]
```

**Arguments:**
- `INPUT_FILE` - Path to input file with comma-separated owed,paid amounts
- `OUTPUT_FILE` - Path to output file for formatted change results

**Options:**
- `--divisor N`, `-d N` - Custom divisor for strategy selection (default: 3)
- `--currency CODE`, `-c CODE` - Currency code: USD, EUR, GBP (default: USD)
- `--help`, `-h` - Show help message
- `--version`, `-v` - Show version information

### Examples

```bash
# Process transactions
./cash_register input.txt output.txt

# Use custom divisor
./cash_register input.txt output.txt --divisor 5

# Use Euro currency
./cash_register input.txt output.txt --currency EUR

# Combine options
./cash_register input.txt output.txt -d 5 -c GBP

# Show help
./cash_register --help

# Show version
./cash_register --version
```

### Input File Format

Each line should contain comma-separated owed,paid amounts in decimal format:

```
2.12,3.00
1.00,2.00
0.75,1.00
5.00,10.00
1.01,2.00
```

### Output

The CLI writes formatted change to the output file, one line per transaction:

```
3 quarters,1 dime,3 pennies
1 dollar
1 quarter
1 five-dollar bill
3 quarters,2 dimes,4 pennies
```

On success, prints: `Success: Change calculated and written to output file`

On error, prints user-friendly error messages to stderr and exits with code 1.

## Library Usage

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
# ["3 quarters,1 dime,3 pennies", "1 dollar", "1 quarter"]

# If any line has an error, returns the first error
CashRegister.process_file("invalid_file.txt")
# {:error, "cannot read file invalid_file.txt: no such file or directory"}
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

Support for EUR currency:

```elixir
# Use Euro denominations
CashRegister.process_transaction(212, 300, currency: "EUR")
# {:ok, "1 euro,1 10-cent coin,2 cents"}
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
- `Currency` - Provides denomination sets for USD and EUR
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
- International currency support (USD, EUR)
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
