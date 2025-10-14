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

    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") to determine denominations
    * `:denominations` - Custom list of denominations to use (overrides currency)
  """

  @type change_item ::
          {id :: String.t(), count :: non_neg_integer(), singular :: String.t(),
           plural :: String.t()}

  @doc """
  Calculates the denomination breakdown for a given change amount.

  Returns `{:ok, change_items}` with a list of change items, or `{:error, reason}`
  if the calculation fails (e.g., invalid currency).

  Each change item contains: `{id, count, singular, plural}`

  Accepts optional keyword arguments for configuration.
  """
  @callback calculate(change_cents :: non_neg_integer(), opts :: keyword()) ::
              {:ok, list(change_item())} | {:error, String.t()}
end
