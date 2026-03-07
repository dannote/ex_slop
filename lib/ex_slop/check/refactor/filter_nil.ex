defmodule ExSlop.Check.Refactor.FilterNil do
  use Credo.Check,
    id: "EXS4001",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.filter(fn x -> x != nil end)` should be `Enum.reject(&is_nil/1)`.

          # bad
          list |> Enum.filter(fn x -> x != nil end)
          list |> Enum.filter(fn x -> x !== nil end)
          list |> Enum.filter(fn x -> !is_nil(x) end)

          # good
          list |> Enum.reject(&is_nil/1)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.filter(list, fn x -> x != nil end)
  # Enum.filter(list, fn x -> x !== nil end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :filter]}, _,
          [_enumerable, {:fn, _, [{:->, _, [[{var, _, _}], body]}]}]} = ast,
         ctx
       ) do
    if nil_check?(body, var) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # list |> Enum.filter(fn x -> x != nil end)
  defp walk(
         {:|>, _,
          [
            _,
            {{:., meta, [{:__aliases__, _, [:Enum]}, :filter]}, _,
             [{:fn, _, [{:->, _, [[{var, _, _}], body]}]}]}
          ]} = ast,
         ctx
       ) do
    if nil_check?(body, var) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  # x != nil
  defp nil_check?({op, _, [{var, _, _}, nil]}, var) when op in [:!=, :!==], do: true

  defp nil_check?({op, _, [{var, _, _}, {:__block__, _, [nil]}]}, var) when op in [:!=, :!==],
    do: true

  # nil != x
  defp nil_check?({op, _, [nil, {var, _, _}]}, var) when op in [:!=, :!==], do: true

  defp nil_check?({op, _, [{:__block__, _, [nil]}, {var, _, _}]}, var) when op in [:!=, :!==],
    do: true

  # !is_nil(x)
  defp nil_check?({:!, _, [{:is_nil, _, [{var, _, _}]}]}, var), do: true
  defp nil_check?({:not, _, [{:is_nil, _, [{var, _, _}]}]}, var), do: true

  defp nil_check?(_, _), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Use `Enum.reject(&is_nil/1)` instead of filtering out nils manually.",
      trigger: "filter",
      line_no: meta[:line]
    )
  end
end
