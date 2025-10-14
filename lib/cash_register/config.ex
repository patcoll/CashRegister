defmodule CashRegister.Config do
  @moduledoc false

  @denominations [
    {"dollar", 100},
    {"quarter", 25},
    {"dime", 10},
    {"nickel", 5},
    {"penny", 1}
  ]

  @divisor Application.compile_env(:cash_register, :divisor, 3)

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

  @doc "Returns configured default divisor."
  @spec divisor() :: pos_integer()
  def divisor, do: @divisor

  @doc """
  Selects the appropriate strategy based on the change amount.

  ## Examples

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
  """
  @spec change_strategy(non_neg_integer(), pos_integer()) :: module()
  def change_strategy(change_cents, divisor \\ @divisor) do
    if rem(change_cents, divisor) == 0 do
      CashRegister.Strategies.Randomized
    else
      CashRegister.Strategies.Greedy
    end
  end
end
