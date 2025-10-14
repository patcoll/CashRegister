defmodule CashRegister.ChangeStrategy do
  @moduledoc """
  Behavior for change calculation strategies.

  Implementations must provide a `calculate/1` function that converts
  a change amount (in cents) into a list of denomination tuples.
  """

  alias CashRegister.Config

  @doc """
  Calculates the denomination breakdown for a given change amount.
  """
  @callback calculate(change_cents :: non_neg_integer()) :: list(Config.denomination())
end
