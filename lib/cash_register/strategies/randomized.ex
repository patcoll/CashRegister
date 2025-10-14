defmodule CashRegister.Strategies.Randomized do
  @moduledoc """
  Randomized strategy for calculating change.

  Shuffles the denomination order before applying the greedy strategy.

  ## Options

    * `:random_seed` - Integer seed for deterministic shuffling (useful for testing and debugging)
  """

  @behaviour CashRegister.ChangeStrategy

  alias CashRegister.Currency
  alias CashRegister.Strategies.Greedy

  @impl true
  def calculate(change_cents, opts \\ []) do
    base_denominations = Currency.resolve_denominations(opts)
    denominations = shuffle_denominations(base_denominations, opts)

    Greedy.calculate(change_cents, denominations: denominations)
  end

  defp shuffle_denominations(denominations, opts) do
    case Keyword.get(opts, :random_seed) do
      nil ->
        Enum.shuffle(denominations)

      seed ->
        :rand.seed(:exsss, {seed, seed, seed})
        Enum.shuffle(denominations)
    end
  end
end
