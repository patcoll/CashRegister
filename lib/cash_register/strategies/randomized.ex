defmodule CashRegister.Strategies.Randomized do
  @moduledoc """
  Randomized strategy for calculating change.

  Shuffles the denomination order before applying the greedy strategy.
  """

  @behaviour CashRegister.ChangeStrategy

  alias CashRegister.Strategies.Greedy

  @impl true
  def calculate(change_cents) do
    denominations = Enum.shuffle(CashRegister.Config.denominations())

    Greedy.calculate(change_cents, denominations: denominations)
  end
end
