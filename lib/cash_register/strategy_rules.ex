defmodule CashRegister.StrategyRules do
  @moduledoc """
  Strategy selection rules pipeline.

  Provides an extensible system for determining which change calculation strategy
  to use based on transaction context and options. Rules are evaluated in order,
  and the first rule that matches determines the strategy. If no rules match,
  the Greedy strategy is used as a fallback.

  This is how we accommodate new special twists in logic that might come!

  ## Rule Functions

  A rule is a function that takes `(context, opts)` where context is a map with:
  - `:owed_cents` - The amount owed in cents
  - `:paid_cents` - The amount paid in cents
  - `:change_cents` - The change amount in cents

  Rules return either:
  - `{:ok, {strategy, metadata}}` - Use this strategy with metadata
  - `{:ok, strategy}` - Use this strategy without metadata
  - `{:error, reason}` - Validation failed
  - `nil` - Rule doesn't match (continue to next rule)

  The metadata map should contain information about why the rule matched, which will
  be included in telemetry events for observability.

  By default, the divisor rule is used which returns the Randomized strategy
  when the owed amount is divisible by 3 (or a custom divisor). Custom rules
  can be provided via the `:strategy_rules` option.
  """

  alias CashRegister.Error

  @type context :: %{
          owed_cents: non_neg_integer(),
          paid_cents: non_neg_integer(),
          change_cents: non_neg_integer()
        }

  @type rule :: (context(), keyword() ->
                   {:ok, {module(), map()}} | {:ok, module()} | {:error, Error.t()} | nil)

  @doc """
  Returns the default list of strategy rules.

  Currently includes only the divisor rule, which returns the Randomized strategy
  when the owed amount is divisible by the configured divisor (default: 3).
  """
  @spec default_rules() :: list(rule())
  def default_rules do
    [&divisor_match/2]
  end

  @doc """
  Divisor-based rule: uses Randomized strategy if owed amount is divisible by divisor.

  Reads the divisor from opts (`:divisor` key, default: 3).

  Returns `{:ok, {Randomized, metadata}}` if the owed amount is divisible by the divisor,
  `{:error, reason}` if divisor is invalid, or `nil` if not divisible.
  """
  @spec divisor_match(context(), keyword()) ::
          {:ok, {module(), map()}} | {:error, Error.t()} | nil
  def divisor_match(%{owed_cents: owed_cents}, opts) do
    divisor = Keyword.get(opts, :divisor, 3)

    cond do
      not is_integer(divisor) or divisor <= 0 ->
        {:error, {:invalid_divisor, %{divisor: divisor}}}

      rem(owed_cents, divisor) == 0 ->
        {:ok, {CashRegister.Strategies.Randomized, %{divisor: divisor, rule: :divisor_match}}}

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
  - `{:ok, {strategy, metadata}}` - Use this strategy with metadata (stop evaluating rules)
  - `{:ok, strategy}` - Use this strategy without metadata (stop evaluating rules)
  - `{:error, reason}` - Validation failed (stop and return error)
  - `nil` - Rule doesn't match (continue to next rule)

  If all rules return nil, defaults to `CashRegister.Strategies.Greedy`.
  """
  @spec select_strategy(context(), keyword()) :: {:ok, module()} | {:error, Error.t()}
  def select_strategy(context, opts \\ []) do
    rules = Keyword.get(opts, :strategy_rules, default_rules())

    result =
      Enum.reduce_while(
        rules,
        {:ok, {CashRegister.Strategies.Greedy, %{rule: :default_fallback}}},
        fn rule, acc ->
          case rule.(context, opts) do
            {:ok, {_strategy, _metadata}} = success -> {:halt, success}
            {:ok, strategy} -> {:halt, {:ok, {strategy, %{}}}}
            {:error, _} = error -> {:halt, error}
            nil -> {:cont, acc}
          end
        end
      )

    case result do
      {:ok, {strategy, rule_metadata}} ->
        metadata =
          rule_metadata
          |> Map.merge(context)
          |> Map.put(:strategy, inspect(strategy))

        :telemetry.execute(
          [:cash_register, :strategy, :selected],
          context,
          metadata
        )

        {:ok, strategy}

      {:error, _reason} = error ->
        error
    end
  end
end
