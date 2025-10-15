defmodule CashRegister.Calculator do
  @moduledoc false

  alias CashRegister.{ChangeStrategy, Error, StrategyRules}

  @doc """
  Calculates change for a transaction.

  Each change item is a 4-tuple: `{id, count, singular, plural}` where count
  indicates how many of that denomination to give.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec calculate(integer(), integer(), keyword()) ::
          {:ok, list(ChangeStrategy.change_item())} | {:error, Error.t()}
  def calculate(owed_cents, paid_cents, opts \\ [])

  def calculate(owed_cents, paid_cents, _opts) when owed_cents < 0 or paid_cents < 0 do
    {:error, {:negative_amount, %{owed: owed_cents, paid: paid_cents}}}
  end

  def calculate(owed_cents, paid_cents, _opts) when paid_cents < owed_cents do
    {:error, {:insufficient_payment, %{owed: owed_cents, paid: paid_cents}}}
  end

  def calculate(owed_cents, paid_cents, opts)
      when is_integer(owed_cents) and is_integer(paid_cents) do
    change_cents = paid_cents - owed_cents

    if change_cents == 0 do
      {:ok, []}
    else
      with {:ok, strategy} <- StrategyRules.select_strategy(change_cents, opts) do
        strategy.calculate(change_cents, opts)
      end
    end
  end
end
