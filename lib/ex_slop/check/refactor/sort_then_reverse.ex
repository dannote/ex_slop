defmodule ExSlop.Check.Refactor.SortThenReverse do
  use Credo.Check,
    id: "EXS4009",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.sort/1 |> Enum.reverse/1` should be `Enum.sort(:desc)`.
      `Enum.sort_by/2 |> Enum.reverse/1` should be `Enum.sort_by(fun, :desc)`.

          # bad
          list |> Enum.sort() |> Enum.reverse()
          Enum.reverse(Enum.sort(list))
          list |> Enum.sort_by(&fun/1) |> Enum.reverse()

          # good
          Enum.sort(list, :desc)
          Enum.sort_by(list, &fun/1, :desc)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.sort(list) |> Enum.reverse()
  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, sort_fn]}, _, [_enumerable]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _, []}
          ]} = ast,
         ctx
       )
       when sort_fn in [:sort, :sort_by] do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # ... |> Enum.sort() |> Enum.reverse()
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, []}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # ... |> Enum.sort_by(fun) |> Enum.reverse()
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :sort_by]}, _, [_fun]}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # Enum.reverse(Enum.sort(list))
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, [_enumerable]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # Enum.reverse(Enum.sort_by(list, fun))
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :sort_by]}, _, [_enumerable, _fun]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`Enum.sort/1 |> Enum.reverse/1` — use `Enum.sort(:desc)` or `Enum.sort_by(fun, :desc)` instead.",
      trigger: "reverse",
      line_no: meta[:line]
    )
  end
end
