defmodule ExSlop.Check.Refactor.ReduceMapPut do
  use Credo.Check,
    id: "EXS4013",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.reduce(%{}, fn x, acc -> Map.put(acc, key, value) end)` is
      `Map.new/2` (or a `for` comprehension).

          # bad — verbose reduce to build a map
          Enum.reduce(batch, %{}, fn event, acc ->
            Map.put(acc, event.id, event)
          end)

          # good — use Map.new
          Map.new(batch, fn event -> {event.id, event} end)

          # good — for comprehension
          for event <- batch, into: %{}, do: {event.id, event}
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.reduce(list, %{}, fn x, acc -> Map.put(acc, k, v) end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [_, {:%{}, _, []}, fun]} = ast,
         ctx
       ) do
    if fn_body_is_only_map_put?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, k, v) end)
  defp walk(
         {:|>, meta,
          [
            _,
            {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [{:%{}, _, []}, fun]}
          ]} = ast,
         ctx
       ) do
    if fn_body_is_only_map_put?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp fn_body_is_only_map_put?({:fn, _, [{:->, _, [[_arg, _acc], body]}]}) do
    body_is_map_put?(body)
  end

  defp fn_body_is_only_map_put?({:fn, _, [{:->, _, [[_arg, _acc], [body]]}]}) do
    body_is_map_put?(body)
  end

  defp fn_body_is_only_map_put?(_), do: false

  defp body_is_map_put?({{:., _, [{:__aliases__, _, [:Map]}, :put]}, _, [acc_name, _, _]})
       when is_atom(acc_name),
       do: true

  defp body_is_map_put?({{:., _, [{:__aliases__, _, [:Map]}, :put]}, _, [{acc_name, _, _} | _]})
       when is_atom(acc_name),
       do: true

  defp body_is_map_put?({:__block__, _, [expr]}), do: body_is_map_put?(expr)
  defp body_is_map_put?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Use `Map.new/2` or `for ... into: %{}` instead of `Enum.reduce(%{}, ..., Map.put/3)`.",
      trigger: "Enum.reduce",
      line_no: meta[:line]
    )
  end
end
