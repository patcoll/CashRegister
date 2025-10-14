defmodule CashRegister.StrategyRules do
  @moduledoc """
  Strategy selection rules pipeline.

  Provides an extensible system for determining which change calculation strategy
  to use based on the change amount and options. Rules are evaluated in order,
  and the first rule that matches determines the strategy. If no rules match,
  the Greedy strategy is used as a fallback.

  This is how we accommodate new special twists in logic that might come!

  ## Rule Functions

  A rule is a function that takes `(change_cents, opts)` and returns either:
  - `{:ok, strategy}` - Use this strategy (stop evaluation)
  - `{:error, reason}` - Validation failed (stop and return error)
  - `nil` - Rule doesn't match (continue to next rule)

  By default, the divisor rule is used which returns the Randomized strategy
  when the change amount is divisible by 3 (or a custom divisor). Custom rules
  can be provided via the `:strategy_rules` option.
  """

  @type rule :: (non_neg_integer(), keyword() -> {:ok, module()} | {:error, String.t()} | nil)

  @doc """
  Returns the default list of strategy rules.

  Currently includes only the divisor rule, which returns the Randomized strategy
  when the change amount is divisible by the configured divisor (default: 3).
  """
  @spec default_rules() :: list(rule())
  def default_rules do
    [&divisor_rule/2]
  end

  @doc """
  Divisor-based rule: uses Randomized strategy if change is divisible by divisor.

  Reads the divisor from opts (`:divisor` key, default: 3).

  Returns `{:ok, Randomized}` if the change amount is divisible by the divisor,
  `{:error, reason}` if divisor is invalid, or `nil` if not divisible.
  """
  @spec divisor_rule(non_neg_integer(), keyword()) ::
          {:ok, module()} | {:error, String.t()} | nil
  def divisor_rule(change_cents, opts) do
    divisor = Keyword.get(opts, :divisor, 3)

    cond do
      not is_integer(divisor) or divisor <= 0 ->
        {:error, "divisor must be a positive integer, got: #{inspect(divisor)}"}

      rem(change_cents, divisor) == 0 ->
        {:ok, CashRegister.Strategies.Randomized}

      true ->
        nil
    end
  end

  @doc """
  Selects the appropriate strategy by evaluating rules in order.

  ## Options

    * `:divisor` - Divisor for the default divisor rule (default: 3)
    * `:strategy_rules` - List of custom rule functions to evaluate (default: uses default_rules/0)

  Rules are evaluated in order and can return:
  - `{:ok, strategy}` - Use this strategy (stop evaluation)
  - `{:error, reason}` - Validation failed (stop and return error)
  - `nil` - Rule doesn't match (continue to next rule)

  If all rules return nil, defaults to `CashRegister.Strategies.Greedy`.
  """
  @spec select_strategy(non_neg_integer(), keyword()) :: {:ok, module()} | {:error, String.t()}
  def select_strategy(change_cents, opts \\ []) do
    rules = Keyword.get(opts, :strategy_rules, default_rules())

    Enum.reduce_while(rules, {:ok, CashRegister.Strategies.Greedy}, fn rule, acc ->
      case rule.(change_cents, opts) do
        {:ok, strategy} -> {:halt, {:ok, strategy}}
        {:error, _} = error -> {:halt, error}
        nil -> {:cont, acc}
      end
    end)
  end
end
