defmodule CashRegister.Strategies.Greedy do
  @moduledoc """
  Greedy algorithm for calculating change.

  Uses denominations in order from largest to smallest.
  """

  @behaviour CashRegister.ChangeStrategy

  alias CashRegister.Currency

  @impl true
  def calculate(change_cents, opts \\ [])

  def calculate(0, _opts), do: []

  def calculate(change_cents, opts) when change_cents > 0 do
    denominations =
      cond do
        Keyword.has_key?(opts, :denominations) ->
          Keyword.get(opts, :denominations)

        Keyword.has_key?(opts, :currency) ->
          Currency.denominations(Keyword.get(opts, :currency))

        true ->
          Currency.denominations()
      end

    denominations
    |> Enum.reduce({change_cents, []}, fn {name, value}, {remaining, result} ->
      count = div(remaining, value)
      new_remaining = rem(remaining, value)

      new_result =
        if count > 0 do
          [{name, count} | result]
        else
          result
        end

      {new_remaining, new_result}
    end)
    |> elem(1)
    |> Enum.reverse()
  end
end
