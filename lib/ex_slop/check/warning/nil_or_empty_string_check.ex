defmodule ExSlop.Check.Warning.NilOrEmptyStringCheck do
  use Credo.Check,
    id: "EXS1008",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      `expr in [nil, ""]` treats missing values and empty strings the same.
      This usually means params weren't normalized at the boundary. Normalize
      once where data enters, then use a simple nil check.

      This check only flags the pattern in `if` expressions (internal logic),
      not in function head guards (which are the correct place for boundary checks).

          # bad — checking both nil and empty string in internal logic
          if Map.get(params, key) in [nil, ""] do
            Map.put(params, key, default)
          end

          # good — normalize at the boundary, then use nil check
          params = normalize_params(raw_params)
          if is_nil(params[key]) do
            Map.put(params, key, default)
          end

          # ok — boundary check in function head guard is fine
          defp cast_date(%{"year" => e, "month" => e, "day" => e}) when e in ["", nil],
            do: {:ok, nil}
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # if expr in [nil, ""] do
  defp walk({:if, meta, [{:in, _, [_expr, [nil, ""]]}, _]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk({:if, meta, [{:in, _, [_expr, ["", nil]]}, _]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`expr in [nil, \"\"]` in `if` — normalize params at the boundary instead of checking both nil and empty string.",
      trigger: "if",
      line_no: meta[:line]
    )
  end
end
