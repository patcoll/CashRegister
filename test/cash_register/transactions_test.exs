defmodule CashRegister.TransactionsTest do
  use ExUnit.Case, async: false

  alias CashRegister.Transactions

  setup do
    # Attach test telemetry handler
    test_pid = self()

    :telemetry.attach_many(
      "transactions-test",
      [
        [:cash_register, :transaction, :start],
        [:cash_register, :transaction, :stop]
      ],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach("transactions-test") end)

    :ok
  end

  describe "transact/3" do
    test "emits start and stop telemetry events on success" do
      assert {:ok, "3 quarters,1 dime,3 pennies"} = Transactions.transact(212, 300)

      # Should receive start event
      assert_receive {:telemetry, [:cash_register, :transaction, :start], %{}, metadata}
      assert metadata.owed_cents == 212
      assert metadata.paid_cents == 300
      assert is_binary(metadata.transaction_id)

      # Should receive stop event with success status
      assert_receive {:telemetry, [:cash_register, :transaction, :stop], %{duration: duration},
                      metadata}

      assert duration > 0
      assert metadata.status == :success
      assert metadata.error_type == nil
    end

    test "emits telemetry events on error" do
      assert {:error, _} = Transactions.transact(300, 200)

      # Insufficient payment
      assert_receive {:telemetry, [:cash_register, :transaction, :start], %{}, _}

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], %{duration: _}, metadata}

      assert metadata.status == :error
      assert metadata.error_type == :validation_error
    end

    test "categorizes currency errors" do
      assert {:error, _} = Transactions.transact(100, 200, currency: "INVALID")

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], _, metadata}
      assert metadata.error_type == :currency_error
    end

    test "categorizes validation errors for negative amounts" do
      assert {:error, _} = Transactions.transact(-100, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], _, metadata}
      assert metadata.error_type == :validation_error
    end

    test "includes transaction_id in metadata" do
      Transactions.transact(100, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata}
      assert is_binary(metadata.transaction_id)
      assert byte_size(metadata.transaction_id) == 16

      # 8 bytes hex encoded
    end

    test "includes currency in metadata" do
      Transactions.transact(100, 200, currency: "EUR")

      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata}
      assert metadata.currency == "EUR"
    end

    test "defaults currency to USD when not provided" do
      Transactions.transact(100, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata}
      assert metadata.currency == "USD"
    end

    test "preserves existing functionality for successful transactions" do
      # Verify that telemetry doesn't break business logic
      assert {:ok, "3 quarters,1 dime,3 pennies"} = Transactions.transact(212, 300)

      assert {:ok, "no change"} = Transactions.transact(100, 100)

      assert {:ok, "1 euro"} = Transactions.transact(100, 200, currency: "EUR")
    end

    test "preserves existing functionality for error cases" do
      assert {:error, reason} = Transactions.transact(-100, 200)
      assert reason =~ "non-negative"

      assert {:error, reason} = Transactions.transact(300, 200)
      assert reason =~ "insufficient"

      assert {:error, reason} = Transactions.transact(100, 200, currency: "INVALID")
      assert reason =~ "unknown currency"
    end

    test "transaction_ids are unique across transactions" do
      Transactions.transact(100, 200)
      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata1}

      Transactions.transact(100, 200)
      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata2}

      assert metadata1.transaction_id != metadata2.transaction_id
    end
  end
end
