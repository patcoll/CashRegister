defmodule CashRegister.Formatter do
  @moduledoc false

  alias CashRegister.Config

  @doc """
  Formats a list of denominations into a comma-separated string.

  Returns "no change" for an empty list.
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
