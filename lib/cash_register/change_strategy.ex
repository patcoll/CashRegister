defmodule CashRegister.ChangeStrategy do
  @moduledoc """
  Behavior for change calculation strategies.

  Implementations must provide a `calculate/2` function that converts
  a change amount (in cents) into a list of denomination tuples.

  ## Options

    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") to determine denominations
    * `:denominations` - Custom list of denominations to use (overrides currency)
  """

  alias CashRegister.Currency

  @doc """
  Calculates the denomination breakdown for a given change amount.

  Accepts optional keyword arguments for configuration.
  """
  @callback calculate(change_cents :: non_neg_integer(), opts :: keyword()) ::
              list(Currency.denomination())
end
