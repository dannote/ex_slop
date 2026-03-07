defmodule ExSlop.Check.Refactor.CaseTrueFalse do
  use Credo.Check,
    id: "EXS4006",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `case` that matches only on `true` and `false` is better expressed
      as `if`/`else`.

          # bad
          case some_condition() do
            true -> :yes
            false -> :no
          end

          # good
          if some_condition(), do: :yes, else: :no
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:case, meta, [_expr, [do: clauses]]} = ast, ctx) when is_list(clauses) do
    if true_false_clauses?(clauses) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp true_false_clauses?([clause_a, clause_b]) do
    patterns = Enum.sort([clause_pattern(clause_a), clause_pattern(clause_b)])
    patterns == [false, true]
  end

  defp true_false_clauses?(_), do: false

  defp clause_pattern({:->, _meta, [[pattern], _body]}), do: pattern
  defp clause_pattern(_), do: nil

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`case` on `true`/`false` — use `if`/`else` instead.",
      trigger: "case",
      line_no: meta[:line]
    )
  end
end
