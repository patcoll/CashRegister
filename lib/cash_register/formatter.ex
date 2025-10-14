defmodule CashRegister.Formatter do
  @moduledoc false

  alias CashRegister.Config

  @doc """
  Formats a list of denominations into a comma-separated string.

  ## Examples

  ```elixir
  iex> CashRegister.Formatter.format([{"quarter", 3}, {"dime", 1}, {"penny", 3}])
  "3 quarters,1 dime,3 pennies"

  iex> CashRegister.Formatter.format([{"dollar", 1}])
  "1 dollar"

  iex> CashRegister.Formatter.format([{"penny", 2}])
  "2 pennies"

  iex> CashRegister.Formatter.format([{"nickel", 1}])
  "1 nickel"

  iex> CashRegister.Formatter.format([])
  "no change"
  ```
  """
  @spec format(list(Config.denomination())) :: String.t()
  def format([]), do: "no change"

  def format(denominations) do
    Enum.map_join(denominations, ",", fn {name, count} ->
      pluralized_name = pluralize(name, count)
      "#{count} #{pluralized_name}"
    end)
  end

  defp pluralize(name, 1), do: name

  defp pluralize("penny", _count), do: "pennies"

  defp pluralize(name, _count), do: "#{name}s"
end
