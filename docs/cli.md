# Command-Line Interface

Build the executable:

```bash
mix escript.build
```

This creates a standalone `cash_register` executable that can be run without Elixir installed.

## Basic Usage

```bash
./cash_register INPUT_FILE OUTPUT_FILE [OPTIONS]
```

**Arguments:**

- `INPUT_FILE` - Path to input file with comma-separated owed,paid amounts
- `OUTPUT_FILE` - Path to output file for formatted change results

**Options:**

- `--divisor N`, `-d N` - Custom divisor for strategy selection (default: 3)
- `--currency CODE`, `-c CODE` - Currency code: USD, EUR (default: USD)
- `--help`, `-h` - Show help message
- `--version`, `-v` - Show version information

## Examples

```bash
# Process transactions
./cash_register input.txt output.txt

# Use custom divisor
./cash_register input.txt output.txt --divisor 5

# Use Euro currency
./cash_register input.txt output.txt --currency EUR

# Combine options
./cash_register input.txt output.txt -d 5 -c EUR

# Show help
./cash_register --help

# Show version
./cash_register --version
```

## Input File Format

Each line should contain comma-separated owed,paid amounts in decimal format:

```
2.12,3.00
1.00,2.00
0.75,1.00
5.00,10.00
1.01,2.00
```

## Output

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
