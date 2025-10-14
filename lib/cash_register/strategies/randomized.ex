defmodule CashRegister.Strategies.Randomized do
  @moduledoc """
  Randomized strategy for calculating change.

  Shuffles the denomination order before applying the greedy strategy.
  """

  @behaviour CashRegister.ChangeStrategy

  alias CashRegister.Currency
  alias CashRegister.Strategies.Greedy

  @impl true
  def calculate(change_cents, opts \\ []) do
    # Get denominations based on currency option if provided
    base_denominations =
      if Keyword.has_key?(opts, :currency) do
        Currency.denominations(Keyword.get(opts, :currency))
      else
        Currency.denominations()
      end

    denominations = Enum.shuffle(base_denominations)

    Greedy.calculate(change_cents, denominations: denominations)
  end
end
