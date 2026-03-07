defmodule ExSlop.Check.Refactor.MapIntoLiteral do
  use Credo.Check,
    id: "EXS4002",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.map(fn {k, v} -> ... end) |> Enum.into(%{})` should be `Map.new/2`.

          # bad
          list
          |> Enum.map(fn {k, v} -> {k, transform(v)} end)
          |> Enum.into(%{})

          # good
          Map.new(list, fn {k, v} -> {k, transform(v)} end)

      Credo's `Refactor.MapInto` is disabled for Elixir >= 1.8 (performance
      was fixed), but `Map.new/2` is still clearer and more intentional.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.map(...) |> Enum.into(%{})
  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :into]}, _, [{:%{}, _, []}]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # ... |> Enum.map(...) |> Enum.into(%{})
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :into]}, _, [{:%{}, _, []}]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # Enum.into(Enum.map(...), %{})
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :into]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {:%{}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Use `Map.new/2` instead of `Enum.map/2 |> Enum.into(%{})`.",
      trigger: "into",
      line_no: meta[:line]
    )
  end
end
