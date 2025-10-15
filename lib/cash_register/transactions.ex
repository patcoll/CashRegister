defmodule CashRegister.Transactions do
  @moduledoc """
  Transaction orchestration and telemetry.

  Handles the end-to-end transaction flow: validation, calculation,
  formatting, and observability instrumentation.
  """

  require Logger
  alias CashRegister.{Calculator, Error, Formatter}

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
          {:ok, String.t()} | {:error, Error.t()}
  def transact(owed_cents, paid_cents, opts \\ []) do
    transaction_id = generate_transaction_id()
    start_time = System.monotonic_time()

    metadata = %{
      transaction_id: transaction_id,
      owed_cents: owed_cents,
      paid_cents: paid_cents,
      currency: opts[:currency] || "USD"
    }

    Logger.metadata(transaction_id: transaction_id)

    :telemetry.execute(
      [:cash_register, :transaction, :start],
      %{},
      metadata
    )

    result = execute_transaction(owed_cents, paid_cents, opts)

    duration = System.monotonic_time() - start_time

    emit_stop_event(result, duration, metadata)

    log_transaction(result, metadata, duration)

    result
  end

  defp execute_transaction(owed_cents, paid_cents, opts) do
    case Calculator.calculate(owed_cents, paid_cents, opts) do
      {:ok, denominations} -> {:ok, Formatter.format(denominations)}
      {:error, reason} -> {:error, reason}
    end
  end

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

  defp emit_stop_event({:error, {error_type, error_metadata}} = _result, duration, metadata) do
    :telemetry.execute(
      [:cash_register, :transaction, :stop],
      %{duration: duration},
      Map.merge(metadata, %{
        status: :error,
        error_type: error_type,
        error_metadata: error_metadata,
        error_category: categorize_error({error_type, error_metadata})
      })
    )
  end

  defp log_transaction({:ok, formatted}, metadata, duration) do
    if should_log_success?() do
      Logger.info("Transaction succeeded",
        owed: metadata.owed_cents,
        paid: metadata.paid_cents,
        currency: metadata.currency,
        change: formatted,
        duration_us: duration
      )
    end
  end

  defp log_transaction({:error, {error_type, error_metadata}}, metadata, duration) do
    Logger.warning("Transaction failed",
      owed: metadata.owed_cents,
      paid: metadata.paid_cents,
      currency: metadata.currency,
      error_type: error_type,
      error_metadata: error_metadata,
      error_category: categorize_error({error_type, error_metadata}),
      duration_us: duration
    )
  end

  defp categorize_error({error_type, _metadata}) do
    case error_type do
      type
      when type in [
             :negative_amount,
             :insufficient_payment,
             :invalid_line_format,
             :invalid_amount_format,
             :invalid_divisor
           ] ->
        :validation_error

      :unknown_currency ->
        :currency_error

      type
      when type in [
             :cannot_make_exact_change,
             :file_read_error,
             :file_write_error
           ] ->
        :system_error
    end
  end

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
