defmodule CashRegister.Config do
  @moduledoc false

  @default_divisor 3

  @doc """
  Selects the appropriate strategy based on the change amount.

  Returns `{:ok, CashRegister.Strategies.Randomized}` if the change is divisible by the divisor,
  otherwise returns `{:ok, CashRegister.Strategies.Greedy}`.

  Returns `{:error, reason}` if the divisor is invalid.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
  """
  @spec change_strategy(non_neg_integer(), keyword()) :: {:ok, module()} | {:error, String.t()}
  def change_strategy(change_cents, opts \\ []) do
    divisor = Keyword.get(opts, :divisor, @default_divisor)

    cond do
      not is_integer(divisor) ->
        {:error, "divisor must be a positive integer, got: #{inspect(divisor)}"}

      divisor <= 0 ->
        {:error, "divisor must be a positive integer, got: #{inspect(divisor)}"}

      rem(change_cents, divisor) == 0 ->
        {:ok, CashRegister.Strategies.Randomized}

      true ->
        {:ok, CashRegister.Strategies.Greedy}
    end
  end
end
