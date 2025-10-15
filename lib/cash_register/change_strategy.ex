defmodule CashRegister.ChangeStrategy do
  @moduledoc """
  Behavior for change calculation strategies.

  Implementations must provide a `calculate/2` function that converts
  a change amount (in cents) into a list of change items.

  Each change item contains: `{id, count, singular_display, plural_display}`

  Note: This differs from `CashRegister.Currency.denomination/0` which has
  **value** in position 2 (the worth of the coin/bill), whereas `change_item/0`
  has **count** in position 2 (how many of that denomination to give).

  ## Options

    * `:currency` - Currency code (e.g., "USD", "EUR") to determine denominations
    * `:denominations` - Custom list of denominations to use (overrides currency)
  """

  alias CashRegister.Error

  @type change_item ::
          {id :: String.t(), count :: non_neg_integer(), singular :: String.t(),
           plural :: String.t()}

  @doc """
  Calculates the denomination breakdown for a given change amount.
  """
  @callback calculate(change_cents :: non_neg_integer(), opts :: keyword()) ::
              {:ok, list(change_item())} | {:error, Error.t()}
end
