defmodule ExSlop do
  @moduledoc """
  Credo plugin that catches AI-generated code slop in Elixir.

  ## Setup

  Add to your `.credo.exs`:

      %{configs: [%{name: "default", plugins: [{ExSlop, []}]}]}

  Or cherry-pick individual checks in `checks.enabled` — see `README.md`.
  """

  import Credo.Plugin

  @core_checks [
    ExSlop.Check.Warning.BlanketRescue,
    ExSlop.Check.Warning.RescueWithoutReraise,
    ExSlop.Check.Warning.RepoAllThenFilter,
    ExSlop.Check.Warning.QueryInEnumMap,
    ExSlop.Check.Warning.GenserverAsKvStore,
    ExSlop.Check.Warning.PathExpandPriv,
    ExSlop.Check.Warning.DualKeyAccess,
    ExSlop.Check.Refactor.FilterNil,
    ExSlop.Check.Refactor.RejectNil,
    ExSlop.Check.Refactor.ReduceAsMap,
    ExSlop.Check.Refactor.MapIntoLiteral,
    ExSlop.Check.Refactor.IdentityPassthrough,
    ExSlop.Check.Refactor.IdentityMap,
    ExSlop.Check.Refactor.CaseTrueFalse,
    ExSlop.Check.Refactor.TryRescueWithSafeAlternative,
    ExSlop.Check.Refactor.WithIdentityElse,
    ExSlop.Check.Refactor.WithIdentityDo,
    ExSlop.Check.Refactor.SortThenReverse,
    ExSlop.Check.Refactor.StringConcatInReduce,
    ExSlop.Check.Refactor.ReduceMapPut,
    ExSlop.Check.Refactor.RedundantBooleanIf,
    ExSlop.Check.Refactor.FlatMapFilter,
    ExSlop.Check.Readability.NarratorDoc,
    ExSlop.Check.Readability.DocFalseOnPublicFunction,
    ExSlop.Check.Readability.BoilerplateDocParams,
    ExSlop.Check.Readability.ObviousComment,
    ExSlop.Check.Readability.StepComment,
    ExSlop.Check.Readability.NarratorComment,
    ExSlop.Check.Readability.UnaliasedModuleUse
  ]

  @high_signal_credence_ports [
    ExSlop.Check.Refactor.RedundantEnumJoinSeparator,
    ExSlop.Check.Refactor.UseMapJoin,
    ExSlop.Check.Refactor.GraphemesLength,
    ExSlop.Check.Refactor.ManualStringReverse,
    ExSlop.Check.Refactor.SortThenAt,
    ExSlop.Check.Refactor.SortForTopK,
    ExSlop.Check.Refactor.ExplicitSumReduce
  ]

  @opt_in_credence_ports [
    ExSlop.Check.Refactor.PreferEnumSlice,
    ExSlop.Check.Refactor.ListFold,
    ExSlop.Check.Refactor.ListLast,
    ExSlop.Check.Refactor.LengthInGuard
  ]

  @recommended_checks [
    ExSlop.Check.Warning.BlanketRescue,
    ExSlop.Check.Warning.RescueWithoutReraise,
    ExSlop.Check.Warning.RepoAllThenFilter,
    ExSlop.Check.Warning.QueryInEnumMap,
    ExSlop.Check.Warning.GenserverAsKvStore,
    ExSlop.Check.Warning.PathExpandPriv,
    ExSlop.Check.Warning.DualKeyAccess,
    ExSlop.Check.Refactor.FilterNil,
    ExSlop.Check.Refactor.RejectNil,
    ExSlop.Check.Refactor.ReduceAsMap,
    ExSlop.Check.Refactor.MapIntoLiteral,
    ExSlop.Check.Refactor.IdentityPassthrough,
    ExSlop.Check.Refactor.IdentityMap,
    ExSlop.Check.Refactor.TryRescueWithSafeAlternative,
    ExSlop.Check.Refactor.WithIdentityElse,
    ExSlop.Check.Refactor.WithIdentityDo,
    ExSlop.Check.Refactor.SortThenReverse,
    ExSlop.Check.Refactor.StringConcatInReduce,
    ExSlop.Check.Refactor.ReduceMapPut,
    ExSlop.Check.Refactor.RedundantBooleanIf,
    ExSlop.Check.Refactor.FlatMapFilter,
    ExSlop.Check.Readability.NarratorDoc,
    ExSlop.Check.Readability.BoilerplateDocParams,
    ExSlop.Check.Readability.NarratorComment,
    ExSlop.Check.Refactor.RedundantEnumJoinSeparator,
    ExSlop.Check.Refactor.GraphemesLength,
    ExSlop.Check.Refactor.ManualStringReverse,
    ExSlop.Check.Refactor.SortThenAt,
    ExSlop.Check.Refactor.SortForTopK,
    ExSlop.Check.Refactor.ExplicitSumReduce
  ]

  @checks @core_checks ++ @high_signal_credence_ports ++ @opt_in_credence_ports

  @default_config "%{configs: [%{name: \"default\", checks: %{extra: #{inspect(Enum.map(@recommended_checks, &{&1, []}))}}}]}"

  def init(exec) do
    register_default_config(exec, @default_config)
  end

  def checks, do: @checks
  def recommended_checks, do: @recommended_checks
end
