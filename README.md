# Cash Register

Calculates change for cash transactions using smart denomination strategies.

## Installation

```bash
mix deps.get
```

## Command-Line Interface

Build and run the standalone executable:

```bash
mix escript.build
./cash_register input.txt output.txt
```

For detailed CLI usage, options, and examples, see [docs/cli.md](docs/cli.md).

## Library Usage

Start an interactive Elixir session:

```bash
iex -S mix
```

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
5.00,10.00
1.01,2.00
```

```elixir
CashRegister.process_file("sample_input.txt")
# ["3 quarters,1 dime,3 pennies", "1 dollar", "1 quarter",
#  "1 five-dollar bill", "3 quarters,24 pennies"]
```

## Options

```elixir
# Custom divisor for randomization behavior
CashRegister.process_transaction(212, 300, divisor: 5)
# {:ok, "3 quarters,1 dime,3 pennies"}

# International currency support
CashRegister.process_transaction(212, 300, currency: "EUR")
# {:ok, "1 50-cent coin,1 20-cent coin,1 10-cent coin,1 5-cent coin,1 2-cent coin,1 cent"}
```

**Additional Documentation:**

- [docs/architecture.md](docs/architecture.md) - Implementation details, custom strategy rules, and architecture
- [docs/observability.md](docs/observability.md) - Telemetry events, metrics, and monitoring setup

## Testing

```bash
mix test                    # Run all tests
mix test --trace            # Detailed output
mix test --cover            # Coverage report
```
