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
      refute metadata.error_type
    end

    test "emits telemetry events on error" do
      assert {:error, _} = Transactions.transact(300, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :start], %{}, _}

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], %{duration: _}, metadata}

      assert metadata.status == :error
      assert metadata.error_type == :insufficient_payment
      assert metadata.error_category == :validation_error
    end

    test "categorizes currency errors" do
      assert {:error, _} = Transactions.transact(100, 200, currency: "INVALID")

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], _, metadata}
      assert metadata.error_type == :unknown_currency
      assert metadata.error_category == :currency_error
    end

    test "categorizes validation errors for negative amounts" do
      assert {:error, _} = Transactions.transact(-100, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :stop], _, metadata}
      assert metadata.error_type == :negative_amount
      assert metadata.error_category == :validation_error
    end

    test "includes transaction_id in metadata" do
      Transactions.transact(100, 200)

      assert_receive {:telemetry, [:cash_register, :transaction, :start], _, metadata}
      assert is_binary(metadata.transaction_id)

      assert String.match?(
               metadata.transaction_id,
               ~r/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
             )
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
      assert {:error, {:negative_amount, %{owed: -100, paid: 200}}} =
               Transactions.transact(-100, 200)

      assert {:error, {:insufficient_payment, %{owed: 300, paid: 200}}} =
               Transactions.transact(300, 200)

      assert {:error, {:unknown_currency, %{currency: "INVALID"}}} =
               Transactions.transact(100, 200, currency: "INVALID")
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
