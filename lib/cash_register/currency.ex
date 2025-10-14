defmodule CashRegister.Currency do
  @moduledoc """
  Currency and denomination configuration.

  Provides currency information and denomination lists for different currencies.
  """

  @default_currency "USD"

  @currencies %{
    "USD" => %{
      name: "US Dollar",
      symbol: "$",
      denominations: [
        {"dollar", 100},
        {"quarter", 25},
        {"dime", 10},
        {"nickel", 5},
        {"penny", 1}
      ]
    },
    "EUR" => %{
      name: "Euro",
      symbol: "€",
      denominations: [
        {"euro_2", 200},
        {"euro", 100},
        {"cent_50", 50},
        {"cent_20", 20},
        {"cent_10", 10},
        {"cent_5", 5},
        {"cent_2", 2},
        {"cent", 1}
      ]
    },
    "GBP" => %{
      name: "British Pound",
      symbol: "£",
      denominations: [
        {"pound_2", 200},
        {"pound", 100},
        {"pence_50", 50},
        {"pence_20", 20},
        {"pence_10", 10},
        {"pence_5", 5},
        {"pence_2", 2},
        {"penny", 1}
      ]
    }
  }

  @type denomination :: {String.t(), pos_integer()}
  @type currency_code :: String.t()
  @type currency_info :: %{
          name: String.t(),
          symbol: String.t(),
          denominations: list(denomination())
        }

  @doc """
  Returns currency denominations in descending order.

  Defaults to US Dollar denominations for backward compatibility.

  ## Examples

      iex> CashRegister.Currency.denominations()
      [{"dollar", 100}, {"quarter", 25}, {"dime", 10}, {"nickel", 5}, {"penny", 1}]

      iex> CashRegister.Currency.denominations("EUR")
      [{"euro_2", 200}, {"euro", 100}, ...]

      iex> CashRegister.Currency.denominations("GBP")
      [{"pound_2", 200}, {"pound", 100}, ...]
  """
  @spec denominations(currency_code()) :: list(denomination())
  def denominations(currency_code \\ @default_currency) when is_binary(currency_code) do
    case Map.get(@currencies, currency_code) do
      nil ->
        raise ArgumentError,
              "unknown currency code: #{inspect(currency_code)}. " <>
                "Available currencies: #{inspect(Map.keys(@currencies))}"

      currency_info ->
        currency_info.denominations
    end
  end

  @doc """
  Returns information about a specific currency.

  ## Examples

      iex> CashRegister.Currency.info("EUR")
      %{name: "Euro", symbol: "€", denominations: [...]}
  """
  @spec info(currency_code()) :: currency_info() | nil
  def info(currency_code) when is_binary(currency_code) do
    Map.get(@currencies, currency_code)
  end

  @doc """
  Returns a list of all supported currency codes.

  ## Examples

      iex> CashRegister.Currency.supported()
      ["EUR", "GBP", "USD"]
  """
  @spec supported() :: list(currency_code())
  def supported do
    Map.keys(@currencies) |> Enum.sort()
  end

  @doc """
  Returns the default currency code.
  """
  @spec default() :: currency_code()
  def default, do: @default_currency
end
