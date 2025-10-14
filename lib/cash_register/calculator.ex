defmodule CashRegister.Calculator do
  @moduledoc false

  alias CashRegister.{Config, Currency}

  @doc """
  Calculates change for a transaction.

  Returns `{:ok, denominations}` with a list of coin/bill denominations needed,
  or `{:error, reason}` if the transaction is invalid.

  ## Options

    * `:divisor` - Custom divisor for strategy selection (default: from config)
    * `:currency` - Currency code (e.g., "USD", "EUR", "GBP") for denomination selection
  """
  @spec calculate(integer(), integer(), keyword()) ::
          {:ok, list(Currency.denomination())} | {:error, String.t()}
  def calculate(owed_cents, paid_cents, opts \\ [])

  def calculate(owed_cents, paid_cents, _opts) when owed_cents < 0 or paid_cents < 0 do
    {:error, "amounts must be non-negative: owed=#{owed_cents}, paid=#{paid_cents}"}
  end

  def calculate(owed_cents, paid_cents, _opts) when paid_cents < owed_cents do
    {:error, "insufficient payment: paid #{paid_cents} cents < owed #{owed_cents} cents"}
  end

  def calculate(owed_cents, paid_cents, opts)
      when is_integer(owed_cents) and is_integer(paid_cents) do
    change_cents = paid_cents - owed_cents

    result =
      if change_cents == 0 do
        []
      else
        strategy = Config.change_strategy(change_cents, opts)
        strategy.calculate(change_cents, opts)
      end

    {:ok, result}
  end
end
