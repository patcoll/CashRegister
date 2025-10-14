defmodule CashRegister.Formatter do
  @moduledoc false

  alias CashRegister.ChangeStrategy

  @doc """
  Formats a list of change items into a comma-separated string.

  Each change item should be a 4-tuple: `{id, count, singular, plural}`
  where count indicates how many of that denomination.

  Returns "no change" for an empty list.
  """
  @spec format(list(ChangeStrategy.change_item())) :: String.t()
  def format([]), do: "no change"

  def format(denominations) do
    Enum.map_join(denominations, ",", fn {_id, count, singular, plural} ->
      display_name = if count == 1, do: singular, else: plural
      "#{count} #{display_name}"
    end)
  end
end
