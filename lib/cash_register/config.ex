defmodule CashRegister.Config do
  @moduledoc false

  @default_divisor 3

  @doc """
  Selects the appropriate strategy based on the change amount.

  Returns `CashRegister.Strategies.Randomized` if the change is divisible by the divisor,
  otherwise returns `CashRegister.Strategies.Greedy`.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
  """
  @spec change_strategy(non_neg_integer(), keyword()) :: module()
  def change_strategy(change_cents, opts \\ []) do
    divisor = Keyword.get(opts, :divisor, @default_divisor)

    if rem(change_cents, divisor) == 0 do
      CashRegister.Strategies.Randomized
    else
      CashRegister.Strategies.Greedy
    end
  end
end
