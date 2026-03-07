defmodule ExSlop do
  @moduledoc """
  Credo checks that catch AI-generated code slop in Elixir.

  Add to `.credo.exs`:

      {ExSlop.Check.Warning.BlanketRescue, []},
      {ExSlop.Check.Warning.RescueWithoutReraise, []},
      {ExSlop.Check.Readability.NarratorDoc, []},
      {ExSlop.Check.Readability.ObviousComment, []},
      {ExSlop.Check.Readability.StepComment, []},
      {ExSlop.Check.Readability.DocRestatesName, []},
      {ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
      {ExSlop.Check.Refactor.FilterNil, []},
      {ExSlop.Check.Refactor.ReduceAsMap, []},
      {ExSlop.Check.Refactor.IdentityPassthrough, []},
      {ExSlop.Check.Refactor.MapIntoLiteral, []},
      {ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
      {ExSlop.Check.Warning.RepoAllThenFilter, []},
      {ExSlop.Check.Warning.QueryInEnumMap, []},
  """

  @checks [
    ExSlop.Check.Warning.BlanketRescue,
    ExSlop.Check.Warning.RescueWithoutReraise,
    ExSlop.Check.Readability.NarratorDoc,
    ExSlop.Check.Readability.ObviousComment,
    ExSlop.Check.Readability.StepComment,
    ExSlop.Check.Readability.DocRestatesName,
    ExSlop.Check.Readability.DocFalseOnPublicFunction,
    ExSlop.Check.Refactor.FilterNil,
    ExSlop.Check.Refactor.ReduceAsMap,
    ExSlop.Check.Refactor.IdentityPassthrough,
    ExSlop.Check.Refactor.MapIntoLiteral,
    ExSlop.Check.Refactor.TryRescueWithSafeAlternative,
    ExSlop.Check.Warning.RepoAllThenFilter,
    ExSlop.Check.Warning.QueryInEnumMap
  ]

  def checks, do: @checks
end
