defmodule CashRegister.Calculator do
  @moduledoc false

  alias CashRegister.Config

  @doc """
  Calculates change for a transaction.

  ## Examples

  ```elixir
  iex> CashRegister.Calculator.calculate(212, 300)
  {:ok, [{"quarter", 3}, {"dime", 1}, {"penny", 3}]}

  iex> CashRegister.Calculator.calculate(100, 100)
  {:ok, []}

  iex> CashRegister.Calculator.calculate(300, 200)
  {:error, "insufficient payment: paid 200 cents < owed 300 cents"}

  iex> {:error, reason} = CashRegister.Calculator.calculate(-100, 200)
  iex> reason =~ "must be non-negative"
  true
  ```
  """
  @spec calculate(integer(), integer()) ::
          {:ok, list(Config.denomination())} | {:error, String.t()}
  def calculate(owed_cents, paid_cents) when owed_cents < 0 or paid_cents < 0 do
    {:error, "amounts must be non-negative: owed=#{owed_cents}, paid=#{paid_cents}"}
  end

  def calculate(owed_cents, paid_cents) when paid_cents < owed_cents do
    {:error, "insufficient payment: paid #{paid_cents} cents < owed #{owed_cents} cents"}
  end

  def calculate(owed_cents, paid_cents)
      when is_integer(owed_cents) and is_integer(paid_cents) do
    change_cents = paid_cents - owed_cents

    result =
      if change_cents == 0 do
        []
      else
        strategy = Config.change_strategy(change_cents)
        strategy.calculate(change_cents)
      end

    {:ok, result}
  end
end
