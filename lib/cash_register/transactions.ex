defmodule CashRegister.Transactions do
  @moduledoc """
  Transaction orchestration and telemetry.

  Handles the end-to-end transaction flow: validation, calculation,
  formatting, and observability instrumentation.
  """

  require Logger
  alias CashRegister.{Calculator, Formatter}

  @doc """
  Processes a transaction from owed/paid amounts to formatted change.

  Returns `{:ok, formatted_change}` or `{:error, reason}`.

  Emits telemetry events:
  - `[:cash_register, :transaction, :start]`
  - `[:cash_register, :transaction, :stop]` (with duration, status)

  ## Options

    * `:divisor` - Custom divisor for strategy selection
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP")
  """
  @spec transact(integer(), integer(), keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def transact(owed_cents, paid_cents, opts \\ []) do
    # Generate transaction context
    transaction_id = generate_transaction_id()
    start_time = System.monotonic_time()

    # Build metadata for telemetry
    metadata = %{
      transaction_id: transaction_id,
      owed_cents: owed_cents,
      paid_cents: paid_cents,
      currency: opts[:currency] || "USD"
    }

    # Set logger context
    Logger.metadata(transaction_id: transaction_id)

    # Emit start event
    :telemetry.execute(
      [:cash_register, :transaction, :start],
      %{system_time: System.system_time()},
      metadata
    )

    # Execute core transaction logic
    result = execute_transaction(owed_cents, paid_cents, opts)

    # Calculate duration
    duration = System.monotonic_time() - start_time

    # Emit stop event with results
    emit_stop_event(result, duration, metadata)

    # Log transaction
    log_transaction(result, metadata, duration)

    result
  end

  # Core transaction execution
  defp execute_transaction(owed_cents, paid_cents, opts) do
    case Calculator.calculate(owed_cents, paid_cents, opts) do
      {:ok, denominations} -> {:ok, Formatter.format(denominations)}
      {:error, reason} -> {:error, reason}
    end
  end

  # Emit telemetry stop event
  defp emit_stop_event({:ok, _formatted} = _result, duration, metadata) do
    :telemetry.execute(
      [:cash_register, :transaction, :stop],
      %{duration: duration},
      Map.merge(metadata, %{
        status: :success,
        error_type: nil
      })
    )
  end

  defp emit_stop_event({:error, reason} = _result, duration, metadata) do
    :telemetry.execute(
      [:cash_register, :transaction, :stop],
      %{duration: duration},
      Map.merge(metadata, %{
        status: :error,
        error_reason: reason,
        error_type: categorize_error(reason)
      })
    )
  end

  # Log transaction results
  defp log_transaction({:ok, formatted}, metadata, duration) do
    if should_log_success?() do
      Logger.info("Transaction succeeded",
        transaction_id: metadata.transaction_id,
        owed: metadata.owed_cents,
        paid: metadata.paid_cents,
        currency: metadata.currency,
        change: formatted,
        duration_us: duration
      )
    end
  end

  defp log_transaction({:error, reason}, metadata, duration) do
    Logger.warning("Transaction failed",
      transaction_id: metadata.transaction_id,
      owed: metadata.owed_cents,
      paid: metadata.paid_cents,
      currency: metadata.currency,
      error: reason,
      error_type: categorize_error(reason),
      duration_us: duration
    )
  end

  # Categorize errors for metrics
  defp categorize_error(reason) when is_binary(reason) do
    cond do
      String.contains?(reason, "non-negative") -> :validation_error
      String.contains?(reason, "insufficient") -> :validation_error
      String.contains?(reason, "unknown currency") -> :currency_error
      String.contains?(reason, "divisor") -> :validation_error
      true -> :system_error
    end
  end

  # Generate unique transaction ID
  defp generate_transaction_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end

  # Sample successful transactions to reduce log volume
  defp should_log_success? do
    sample_rate = Application.get_env(:cash_register, :log_sample_rate, 1.0)
    :rand.uniform() <= sample_rate
  end
end
