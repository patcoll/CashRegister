defmodule CashRegister.Config do
  @moduledoc false

  @default_divisor 3

  @denominations [
    {"dollar", 100},
    {"quarter", 25},
    {"dime", 10},
    {"nickel", 5},
    {"penny", 1}
  ]

  @type denomination :: {String.t(), pos_integer()}

  @doc """
  Returns the US currency denominations in descending order.

  ## Examples

  ```elixir
  iex> denoms = CashRegister.Config.denominations()
  iex> length(denoms)
  5
  iex> hd(denoms)
  {"dollar", 100}
  iex> List.last(denoms)
  {"penny", 1}
  ```
  """
  @spec denominations() :: list(denomination())
  def denominations, do: @denominations

  @doc """
  Selects the appropriate strategy based on the change amount.

  ## Examples

  With default divisor (3):

  ```elixir
  iex> CashRegister.Config.change_strategy(99)
  CashRegister.Strategies.Randomized
  iex> CashRegister.Config.change_strategy(3)
  CashRegister.Strategies.Randomized
  iex> CashRegister.Config.change_strategy(300)
  CashRegister.Strategies.Randomized

  iex> CashRegister.Config.change_strategy(88)
  CashRegister.Strategies.Greedy
  iex> CashRegister.Config.change_strategy(100)
  CashRegister.Strategies.Greedy
  iex> CashRegister.Config.change_strategy(1)
  CashRegister.Strategies.Greedy
  ```

  With custom divisor via options:

  ```elixir
  iex> CashRegister.Config.change_strategy(100, divisor: 5)
  CashRegister.Strategies.Randomized
  iex> CashRegister.Config.change_strategy(88, divisor: 5)
  CashRegister.Strategies.Greedy
  ```

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
