# ExSlop

Credo checks that catch AI-generated code slop in Elixir.

Detects patterns that LLMs produce but experienced Elixir developers don't:
blanket rescues, narrator docs, obvious comments, anti-idiomatic Enum usage,
try/rescue around non-raising functions, N+1 queries, and more.

None of these overlap with built-in Credo checks.

## Installation

```elixir
def deps do
  [{:ex_slop, "~> 0.1", only: [:dev, :test], runtime: false}]
end
```

Add checks to `.credo.exs`:

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          # ... existing checks ...

          # ExSlop — AI slop detection
          {ExSlop.Check.Warning.BlanketRescue, []},
          {ExSlop.Check.Warning.RescueWithoutReraise, []},
          {ExSlop.Check.Warning.RepoAllThenFilter, []},
          {ExSlop.Check.Warning.QueryInEnumMap, []},
          {ExSlop.Check.Refactor.FilterNil, []},
          {ExSlop.Check.Refactor.ReduceAsMap, []},
          {ExSlop.Check.Refactor.MapIntoLiteral, []},
          {ExSlop.Check.Refactor.IdentityPassthrough, []},
          {ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
          {ExSlop.Check.Readability.NarratorDoc, []},
          {ExSlop.Check.Readability.DocRestatesName, []},
          {ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
          {ExSlop.Check.Readability.ObviousComment, []},
          {ExSlop.Check.Readability.StepComment, []},
        ]
      }
    }
  ]
}
```

## What it catches

### Warnings

| Check | Example |
|-------|---------|
| `BlanketRescue` | `rescue _ -> nil` or `rescue _e -> {:error, "..."}` |
| `RescueWithoutReraise` | `rescue e -> Logger.error(...); :error` |
| `RepoAllThenFilter` | `Repo.all(User) \|> Enum.filter(& &1.active)` |
| `QueryInEnumMap` | `Enum.map(users, fn u -> Repo.all(...) end)` |

### Refactoring

| Check | Bad | Good |
|-------|-----|------|
| `FilterNil` | `Enum.filter(fn x -> x != nil end)` | `Enum.reject(&is_nil/1)` |
| `ReduceAsMap` | `Enum.reduce([], fn x, acc -> [f(x) \| acc] end)` | `Enum.map(&f/1)` |
| `MapIntoLiteral` | `Enum.map(...) \|> Enum.into(%{})` | `Map.new(...)` |
| `IdentityPassthrough` | `case r do {:ok, v} -> {:ok, v}; ... end` | `r` |
| `TryRescueWithSafeAlternative` | `try do String.to_integer(x) rescue _ -> nil end` | `Integer.parse(x)` |

### Readability

| Check | Example |
|-------|---------|
| `NarratorDoc` | `@moduledoc "This module provides functionality for..."` |
| `DocRestatesName` | `@doc "Creates a new user."` on `create_user/1` |
| `DocFalseOnPublicFunction` | `@doc false` on `def` (not `defp`) |
| `ObviousComment` | `# Fetch the user from the database` |
| `StepComment` | `# Step 1: Validate input` |

## Why not Credo?

Credo covers ~100 checks, but none of these. Specifically:

- Credo never inspects comment or doc **content** (only presence)
- Blanket `rescue _ -> nil` is completely unchecked
- `Enum.filter(fn x -> x != nil end)` is not detected
- `try/rescue` around `String.to_integer` vs `Integer.parse` — not detected
- Ecto anti-patterns (`Repo.all |> Enum.filter`, N+1) — not in scope for Credo
- `Enum.map |> Enum.into(%{})` — Credo's `MapInto` is disabled for Elixir ≥ 1.8
- Identity `case` passthrough — Credo's `CaseTrivialMatches` is deprecated

## License

[MIT](LICENSE)
