defmodule ExSlop.Check.Refactor.ReduceAsMap do
  use Credo.Check,
    id: "EXS4003",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.reduce([], fn x, acc -> [f(x) | acc] end)` is just `Enum.map/2`.

          # bad — manually building a reversed list
          Enum.reduce(items, [], fn item, acc ->
            [transform(item) | acc]
          end)

          # bad — O(n²) list concatenation
          Enum.reduce(items, [], fn item, acc ->
            acc ++ [transform(item)]
          end)

          # good
          Enum.map(items, &transform/1)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.reduce(enum, [], fn x, acc -> [expr | acc] end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _,
          [
            _enumerable,
            {:__block__, _, [[]]},
            {:fn, _, [{:->, _, [[_item, {acc_name, _, _}], body]}]}
          ]} = ast,
         ctx
       ) do
    if reduce_as_map?(body, acc_name) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # list |> Enum.reduce([], fn x, acc -> [expr | acc] end)
  defp walk(
         {:|>, _,
          [
            _,
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _,
             [
               {:__block__, _, [[]]},
               {:fn, _, [{:->, _, [[_item, {acc_name, _, _}], body]}]}
             ]}
          ]} = ast,
         ctx
       ) do
    if reduce_as_map?(body, acc_name) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  # [expr | acc] — prepend pattern
  defp reduce_as_map?([{:|, _, [_expr, {acc, _, _}]}], acc), do: true
  defp reduce_as_map?({:__block__, _, [[{:|, _, [_expr, {acc, _, _}]}]]}, acc), do: true

  # acc ++ [expr] — append pattern (O(n²))
  defp reduce_as_map?({:++, _, [{acc, _, _}, [_expr]]}, acc), do: true

  defp reduce_as_map?(_, _), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`Enum.reduce/3` building a list is just `Enum.map/2` — simpler and communicates intent.",
      trigger: "reduce",
      line_no: meta[:line]
    )
  end
end
