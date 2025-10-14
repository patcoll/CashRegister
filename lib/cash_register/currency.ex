defmodule CashRegister.Currency do
  @moduledoc """
  Currency and denomination configuration.

  Provides currency information and denomination lists for different currencies.

  ## Denomination Structure

  A denomination defines a coin or bill type with its value and display names:
  `{id, value_cents, singular, plural}`

  - `id`: Unique identifier (e.g., "quarter", "euro_2")
  - `value_cents`: Worth of this denomination in cents (positive integer)
  - `singular`: Display name for count=1 (e.g., "quarter", "2-euro coin")
  - `plural`: Display name for count≠1 (e.g., "quarters", "2-euro coins")

  Note: This differs from `CashRegister.ChangeStrategy.change_item/0` which has
  **count** in position 2 (how many to give), whereas `denomination/0` has
  **value** in position 2 (what it's worth).
  """

  @default_currency "USD"

  @currencies %{
    "USD" => %{
      name: "US Dollar",
      symbol: "$",
      denominations: [
        {"dollar", 100, "dollar", "dollars"},
        {"quarter", 25, "quarter", "quarters"},
        {"dime", 10, "dime", "dimes"},
        {"nickel", 5, "nickel", "nickels"},
        {"penny", 1, "penny", "pennies"}
      ]
    },
    "EUR" => %{
      name: "Euro",
      symbol: "€",
      denominations: [
        {"euro_2", 200, "2-euro coin", "2-euro coins"},
        {"euro", 100, "euro", "euros"},
        {"cent_50", 50, "50-cent coin", "50-cent coins"},
        {"cent_20", 20, "20-cent coin", "20-cent coins"},
        {"cent_10", 10, "10-cent coin", "10-cent coins"},
        {"cent_5", 5, "5-cent coin", "5-cent coins"},
        {"cent_2", 2, "2-cent coin", "2-cent coins"},
        {"cent", 1, "cent", "cents"}
      ]
    },
    "GBP" => %{
      name: "British Pound",
      symbol: "£",
      denominations: [
        {"pound_2", 200, "2-pound coin", "2-pound coins"},
        {"pound", 100, "pound", "pounds"},
        {"pence_50", 50, "50-pence coin", "50-pence coins"},
        {"pence_20", 20, "20-pence coin", "20-pence coins"},
        {"pence_10", 10, "10-pence coin", "10-pence coins"},
        {"pence_5", 5, "5-pence coin", "5-pence coins"},
        {"pence_2", 2, "2-pence coin", "2-pence coins"},
        {"penny", 1, "penny", "pennies"}
      ]
    }
  }

  @type denomination_id :: String.t()
  @type display_name :: String.t()

  @type denomination ::
          {id :: denomination_id(), value_cents :: pos_integer(), singular :: display_name(),
           plural :: display_name()}
  @type currency_code :: String.t()
  @type currency_info :: %{
          name: display_name(),
          symbol: String.t(),
          denominations: list(denomination())
        }

  @doc """
  Returns currency denominations in descending order.

  Each denomination is a 4-tuple: `{id, value, singular_display, plural_display}`

  Defaults to US Dollar denominations for backward compatibility.

  ## Examples

      iex> CashRegister.Currency.denominations()
      [{"dollar", 100, "dollar", "dollars"}, {"quarter", 25, "quarter", "quarters"}, ...]

      iex> CashRegister.Currency.denominations("EUR")
      [{"euro_2", 200, "2-euro coin", "2-euro coins"}, {"euro", 100, "euro", "euros"}, ...]

      iex> CashRegister.Currency.denominations("GBP")
      [{"pound_2", 200, "2-pound coin", "2-pound coins"}, {"pound", 100, "pound", "pounds"}, ...]
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
  Resolves denominations from options with priority ordering.

  Priority (highest to lowest):
  1. Custom `:denominations` list provided in opts
  2. `:currency` code provided in opts
  3. Default currency denominations

  ## Examples

      iex> CashRegister.Currency.resolve_denominations([])
      [{"dollar", 100, "dollar", "dollars"}, {"quarter", 25, "quarter", "quarters"}, ...]

      iex> CashRegister.Currency.resolve_denominations(currency: "EUR")
      [{"euro_2", 200, "2-euro coin", "2-euro coins"}, {"euro", 100, "euro", "euros"}, ...]

      iex> CashRegister.Currency.resolve_denominations(denominations: [{"custom", 50, "custom", "customs"}])
      [{"custom", 50, "custom", "customs"}]
  """
  @spec resolve_denominations(keyword()) :: list(denomination())
  def resolve_denominations(opts) when is_list(opts) do
    cond do
      Keyword.has_key?(opts, :denominations) ->
        Keyword.get(opts, :denominations)

      Keyword.has_key?(opts, :currency) ->
        denominations(Keyword.get(opts, :currency))

      true ->
        denominations()
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
