defmodule CashRegister.Error do
  @moduledoc """
  Centralized error type definitions for the cash register system.

  All errors are returned as `{:error, {error_type, metadata}}` tuples where:
  - `error_type` is an atom identifying the specific error
  - `metadata` is a map containing relevant context for debugging/logging

  Errors are categorized into three types:
  - **Validation errors**: User input problems (negative amounts, invalid formats, etc.)
  - **Currency errors**: Currency configuration issues (unknown currency codes)
  - **System errors**: System/configuration issues (file I/O, exact change impossible)
  """

  @typedoc """
  Validation errors occur due to invalid user input or transaction parameters.
  """
  @type validation_error ::
          {:negative_amount, %{owed: integer(), paid: integer()}}
          | {:insufficient_payment, %{owed: integer(), paid: integer()}}
          | {:invalid_line_format, %{line: String.t()}}
          | {:invalid_amount_format, %{amount: String.t(), reason: String.t()}}
          | {:invalid_divisor, %{divisor: any()}}

  @typedoc """
  Currency errors occur when currency configuration is invalid.
  """
  @type currency_error ::
          {:unknown_currency, %{currency: String.t()}}

  @typedoc """
  System errors occur due to system or configuration issues.
  """
  @type system_error ::
          {:cannot_make_exact_change, %{remaining: integer(), change_cents: integer()}}
          | {:file_read_error, %{path: String.t(), reason: atom()}}
          | {:file_write_error, %{path: String.t(), reason: atom()}}

  @typedoc """
  All possible error types in the cash register system.
  """
  @type t :: validation_error() | currency_error() | system_error()
end
