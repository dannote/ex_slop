defmodule ExSlop.Check.Refactor.IdentityPassthrough do
  use Credo.Check,
    id: "EXS4004",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `case` or `with` that matches patterns only to return the same thing
      is a no-op — just return the value directly.

          # bad — identity passthrough
          case result do
            {:ok, value} -> {:ok, value}
            {:error, reason} -> {:error, reason}
          end

          # good
          result

          # bad — with + else that does nothing
          with {:ok, result} <- do_something() do
            {:ok, result}
          else
            {:error, reason} -> {:error, reason}
          end

          # good
          do_something()
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # case expr do pattern1 -> pattern1; pattern2 -> pattern2 end
  defp walk({:case, meta, [_expr, [do: clauses]]} = ast, ctx) when is_list(clauses) do
    if length(clauses) >= 2 and Enum.all?(clauses, &identity_clause?/1) do
      {ast, put_issue(ctx, issue_for(ctx, meta, "case"))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp identity_clause?({:->, _meta, [[pattern], body]}) do
    Credo.Code.remove_metadata(pattern) == Credo.Code.remove_metadata(body)
  end

  defp identity_clause?(_), do: false

  defp issue_for(ctx, meta, trigger) do
    format_issue(ctx,
      message:
        "Identity `#{trigger}` — every clause returns what it matched. Just return the value.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
