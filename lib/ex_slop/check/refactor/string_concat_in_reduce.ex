defmodule ExSlop.Check.Refactor.StringConcatInReduce do
  use Credo.Check,
    id: "EXS4011",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.reduce/3` that builds a string via `<>` concatenation is O(n²).

          # bad
          Enum.reduce(list, "", fn item, acc -> acc <> item end)
          Enum.reduce(list, "", fn item, acc -> acc <> to_string(item) end)

          # good
          Enum.join(list)
          Enum.map_join(list, &to_string/1)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.reduce(enum, "", fn x, acc -> body end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _,
          [
            _enumerable,
            "",
            {:fn, _, [{:->, _, [[_item, {acc_name, _, _}], body]}]}
          ]} = ast,
         ctx
       ) do
    if concat_with_acc?(body, acc_name) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # enum |> Enum.reduce("", fn x, acc -> body end)
  defp walk(
         {:|>, _,
          [
            _,
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _,
             [
               "",
               {:fn, _, [{:->, _, [[_item, {acc_name, _, _}], body]}]}
             ]}
          ]} = ast,
         ctx
       ) do
    if concat_with_acc?(body, acc_name) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  # acc <> expr
  defp concat_with_acc?({:<>, _, [{acc, _, _}, _]}, acc), do: true
  # expr <> acc
  defp concat_with_acc?({:<>, _, [_, {acc, _, _}]}, acc), do: true
  defp concat_with_acc?(_, _), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "String concatenation in `Enum.reduce/3` is O(n²) — use `Enum.join/1`, `Enum.map_join/3`, or IO data.",
      trigger: "reduce",
      line_no: meta[:line]
    )
  end
end
