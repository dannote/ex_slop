defmodule ExSlop.Check.Refactor.LengthComparison do
  use Credo.Check,
    id: "EXS4027",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      Comparing `length/1` against an integer literal walks the whole list just
      to answer a question about its size.

      Unlike `LengthInGuard`, this fires in any context — guard or body — so
      moving the comparison out of a guard into an `if` does not hide the
      problem, it just relocates it.

          # bad
          if length(list) == 0, do: :empty
          def page(list) when length(list) > 0, do: ...
          length(items) <= 5

          # good — emptiness
          if list == [], do: :empty          # or Enum.empty?(list)
          def page([_ | _]), do: ...

          # good — exact/maximum size
          case list do
            [_, _] -> ...
          end

          # good — threshold on a large or lazy enum
          Enum.count_until(items, 6) <= 5

      `length/1` itself is fine when you genuinely need the count (logging,
      arithmetic, a value you reuse) — only the comparison against a literal is
      flagged.
      """
    ]

  @comparison_ops [:==, :!=, :>, :<, :>=, :<=]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({op, meta, [left, right]} = ast, ctx) when op in @comparison_ops do
    if length_vs_literal?(left, right) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp length_vs_literal?(left, right) do
    (length_call?(left) and is_integer(right)) or (is_integer(left) and length_call?(right))
  end

  defp length_call?({:length, _, [_]}), do: true
  defp length_call?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Avoid comparing `length/1` against a literal; it traverses the whole list. " <>
          "Use pattern matching (`[]`, `[_ | _]`) or `Enum.count_until/2` for a threshold.",
      trigger: "length",
      line_no: meta[:line]
    )
  end
end
