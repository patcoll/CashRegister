defmodule CashRegister.Strategies.Greedy do
  @moduledoc """
  Greedy algorithm for calculating change.

  Uses denominations in order from largest to smallest.
  """

  @behaviour CashRegister.ChangeStrategy

  alias CashRegister.Currency

  @impl true
  def calculate(change_cents, opts \\ [])

  def calculate(0, _opts), do: {:ok, []}

  def calculate(change_cents, opts) when change_cents > 0 do
    case Currency.resolve_denominations(opts) do
      {:ok, denominations} ->
        {remaining, result} =
          denominations
          |> Enum.reduce({change_cents, []}, &add_denomination/2)

        if remaining != 0 do
          {:error,
           "cannot make exact change: #{remaining} cents remaining with given denominations"}
        else
          {:ok, Enum.reverse(result)}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_denomination({id, value, singular, plural}, {remaining, result}) do
    count = div(remaining, value)
    new_remaining = rem(remaining, value)

    new_result =
      if count > 0 do
        [{id, count, singular, plural} | result]
      else
        result
      end

    {new_remaining, new_result}
  end
end
