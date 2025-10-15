defmodule CashRegister.Error do
  @moduledoc """
  Centralized error type definitions for the cash register system.
  """

  @type validation_error ::
          {:negative_amount, %{owed: integer(), paid: integer()}}
          | {:insufficient_payment, %{owed: integer(), paid: integer()}}
          | {:invalid_line_format, %{line: String.t()}}
          | {:invalid_amount_format, %{amount: String.t(), reason: String.t()}}
          | {:invalid_divisor, %{divisor: any()}}

  @type currency_error ::
          {:unknown_currency, %{currency: String.t()}}

  @type system_error ::
          {:cannot_make_exact_change, %{remaining: integer(), change_cents: integer()}}
          | {:file_read_error, %{path: String.t(), reason: atom()}}
          | {:file_write_error, %{path: String.t(), reason: atom()}}

  @type t :: validation_error() | currency_error() | system_error()
end
