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
    case Currency.resolve_denominations(opts) do
      {:ok, base_denominations} ->
        denominations = shuffle_denominations(base_denominations, opts)
        Greedy.calculate(change_cents, denominations: denominations)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp shuffle_denominations(denominations, opts) do
    case Keyword.get(opts, :random_seed) do
      nil ->
        Enum.shuffle(denominations)

      seed ->
        # Save current random state to avoid polluting global state
        # Note: export_seed returns :undefined if random was never initialized
        original_state = :rand.export_seed()

        # Set our deterministic seed
        :rand.seed(:exsss, {seed, seed, seed})

        # Shuffle with our seed
        shuffled = Enum.shuffle(denominations)

        # Restore original random state
        case original_state do
          :undefined ->
            # If there was no prior state, re-seed with random data
            # to avoid leaving process in deterministic state
            :rand.seed(:exsss)

          state ->
            # Restore the exact previous state
            :rand.seed(state)
        end

        shuffled
    end
  end
end
