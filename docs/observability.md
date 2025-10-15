# Observability Guide

The system emits telemetry events for monitoring. This guide shows you how to use them.

## Quick Start

Here's a 5-minute example that prints events to console:

```elixir
:telemetry.attach_many(
  "console-logger",
  [
    [:cash_register, :transaction, :start],
    [:cash_register, :transaction, :stop],
    [:cash_register, :strategy, :selected]
  ],
  fn event, measurements, metadata, _config ->
    IO.inspect({event, measurements, metadata}, label: "Telemetry")
  end,
  nil
)
```

Run some transactions and watch the events print.

## Telemetry Events

### Transaction Start

**Event:** `[:cash_register, :transaction, :start]`

**Measurements:** None

**Metadata:**

- `transaction_id` - UUID v7 for tracing
- `owed_cents` - Amount owed
- `paid_cents` - Amount paid
- `currency` - Currency code (USD, EUR, GBP)

### Transaction Stop

**Event:** `[:cash_register, :transaction, :stop]`

**Measurements:**

- `duration` - Time in native units (convert with `System.convert_time_unit/3`)

**Metadata:**

- `transaction_id` - Same ID from start
- `owed_cents`, `paid_cents`, `currency` - Same as start
- `status` - `:success` or `:error`
- `error_type` - Specific error if status is `:error`
- `error_category` - `:validation_error`, `:currency_error`, or `:system_error`

### Strategy Selected

**Event:** `[:cash_register, :strategy, :selected]`

**Measurements:**

- `change_cents` - Amount of change

**Metadata:**

- `strategy` - Module name (e.g., "CashRegister.Strategies.Randomized")
- `rule` - Which rule matched (`:divisor_match` or `:default_fallback`)
- `divisor` - Only present when divisor_match rule applies

## Error Categories

**Validation errors** (expected from bad input):

- `:negative_amount`, `:insufficient_payment`, `:invalid_line_format`, `:invalid_amount_format`, `:invalid_divisor`

**Currency errors:**

- `:unknown_currency`

**System errors** (unexpected):

- `:cannot_make_exact_change`, `:file_read_error`, `:file_write_error`

## Metrics Setup

Add to `mix.exs`:

```elixir
{:telemetry_metrics, "~> 1.0"}
```

Define metrics:

```elixir
defmodule MyApp.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      # Count all transactions
      counter("cash_register.transaction.stop.count",
        tags: [:status, :currency]
      ),

      # Track latency
      distribution("cash_register.transaction.stop.duration",
        unit: {:native, :millisecond},
        tags: [:status],
        reporter_options: [buckets: [10, 50, 100, 500, 1000]]
      ),

      # Count errors by type
      counter("cash_register.transaction.stop.error_count",
        tags: [:error_type, :error_category],
        tag_values: fn meta ->
          if meta.status == :error do
            %{error_type: meta.error_type, error_category: meta.error_category}
          else
            %{}
          end
        end
      )
    ]
  end
end
```

## Prometheus Integration

Add to `mix.exs`:

```elixir
{:telemetry_metrics_prometheus, "~> 1.1"}
```

Add to your supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {TelemetryMetricsPrometheus,
        metrics: MyApp.Telemetry.metrics(),
        port: 9568
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Metrics will be available at `http://localhost:9568/metrics`.

Configure Prometheus scraping:

```yaml
scrape_configs:
  - job_name: "cash_register"
    static_configs:
      - targets: ["localhost:9568"]
```

## Key Queries

**Transaction rate:**

```promql
rate(cash_register_transaction_stop_count[5m])
```

**Success rate:**

```promql
rate(cash_register_transaction_stop_count{status="success"}[5m])
/
rate(cash_register_transaction_stop_count[5m])
* 100
```

**P95 latency:**

```promql
histogram_quantile(0.95,
  rate(cash_register_transaction_stop_duration_bucket[5m])
)
```

**Error breakdown:**

```promql
rate(cash_register_transaction_stop_error_count[5m])
```

## Alerts

**High error rate:**

```yaml
alert: CashRegisterHighErrorRate
expr: |
  rate(cash_register_transaction_stop_count{status="error"}[5m])
  / rate(cash_register_transaction_stop_count[5m])
  > 0.05
for: 5m
severity: critical
```

5% threshold allows for some validation errors but catches real problems.

**Slow transactions:**

```yaml
alert: CashRegisterSlowTransactions
expr: |
  histogram_quantile(0.95,
    rate(cash_register_transaction_stop_duration_bucket[5m])
  ) > 500
for: 5m
severity: warning
```

Should be fast (< 100ms normally). 500ms means something's wrong.

**System errors:**

```yaml
alert: CashRegisterSystemError
expr: |
  rate(cash_register_transaction_stop_error_count{error_category="system_error"}[5m]) > 0
for: 1m
severity: critical
```

System errors mean bugs or infrastructure problems. Alert immediately.

## Logging

Successful transactions are sampled to reduce log volume. Configure in `config/config.exs`:

```elixir
config :cash_register,
  log_sample_rate: 0.1  # 10% of successful transactions
```

Errors are always logged.

Every transaction has a UUID v7 ID that links logs and metrics. Use it to trace problematic transactions.

## Troubleshooting

**High error rate?** Check error breakdown by type:

```promql
rate(cash_register_transaction_stop_error_count[5m])
```

If validation errors: check input format.
If system errors: check denominations, file permissions, system resources.

**Slow transactions?** Check if P95 is high but P50 is fine (GC pauses) or if all percentiles are high (CPU/overload).

**Strategy not matching?** Verify divisor configuration and check rule metadata in telemetry events.

## Next Steps

1. Start with the Quick Start to see events
2. Define metrics for your monitoring system
3. Set up Prometheus (or other backend)
4. Create dashboards with the key queries
5. Configure alerts

See test files for more examples:

- `test/cash_register/transactions_test.exs`
- `test/cash_register/strategy_rules_test.exs`
