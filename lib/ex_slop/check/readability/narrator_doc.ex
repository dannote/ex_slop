defmodule ExSlop.Check.Readability.NarratorDoc do
  use Credo.Check,
    id: "EXS3001",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      `@moduledoc` and `@doc` that begin with "This module/function provides..."
      are narrator comments — they restate what the module or function name
      already says.

          # bad
          @moduledoc \"""
          This module provides functionality for handling user authentication.
          \"""
          defmodule MyApp.Auth do

          # bad
          @doc \"""
          This function creates a new user.
          \"""
          def create_user(attrs)

          # good — explain WHY, not WHAT
          @moduledoc \"""
          Wraps Bcrypt and session token generation.
          Rate-limits login attempts per IP via a sliding window.
          \"""

          # good — document behavior, constraints, examples
          @doc \"""
          Passwords must be at least 12 characters. Returns
          `{:error, :weak_password}` for common dictionary words.

          ## Examples

              iex> create_user(%{email: "a@b.c", password: "hunter2"})
              {:error, :weak_password}
          \"""
      """
    ]

  @narrator_pattern ~r/\A\s*(?:The\s+`?\w+`?\s+|This\s+)(?:module|function|struct|schema|plug|controller|view|component|live\s?view|channel|socket|endpoint|router|context|worker|server|supervisor|task|behaviour|macro)\s+(?:provides?|handles?|is\s+responsible\s+for|is\s+used\s+(?:to|for)|manages?|implements?|defines?|contains?|represents?|serves?\s+as|acts?\s+as|holds?|stores?|wraps?|encapsulates?|exposes?)/i

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # @moduledoc "..." or @moduledoc """..."""
  defp walk({:@, _, [{:moduledoc, meta, [docstring]}]} = ast, ctx) when is_binary(docstring) do
    if narrator?(docstring) do
      {ast, put_issue(ctx, issue_for(ctx, meta, "@moduledoc"))}
    else
      {ast, ctx}
    end
  end

  # @doc "..." or @doc """..."""
  defp walk({:@, _, [{:doc, meta, [docstring]}]} = ast, ctx) when is_binary(docstring) do
    if narrator?(docstring) do
      {ast, put_issue(ctx, issue_for(ctx, meta, "@doc"))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp narrator?(docstring) do
    first_line = docstring |> String.trim_leading() |> String.split("\n", parts: 2) |> hd()
    Regex.match?(@narrator_pattern, first_line)
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(ctx,
      message:
        "\"This module/function provides...\" restates the name — explain WHY or delete the doc.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
