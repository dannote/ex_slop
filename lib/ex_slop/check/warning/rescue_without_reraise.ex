defmodule ExSlop.Check.Warning.RescueWithoutReraise do
  use Credo.Check,
    id: "EXS1004",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `rescue` that logs the error but doesn't re-raise or return it
      silently swallows failures. Callers will never know something went wrong.

          # bad — logs then returns a generic atom
          rescue
            e ->
              Logger.error("Failed: \#{inspect(e)}")
              :error

          # good — log and re-raise
          rescue
            e ->
              Logger.error("Failed: \#{Exception.message(e)}")
              reraise e, __STACKTRACE__

          # good — return the actual exception info
          rescue
            e in RuntimeError ->
              {:error, Exception.message(e)}
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:try, _, [blocks]} = ast, ctx) when is_list(blocks) do
    case Keyword.get(blocks, :rescue, []) do
      clauses when is_list(clauses) -> {ast, Enum.reduce(clauses, ctx, &check_clause/2)}
      _ -> {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp check_clause({:->, meta, [[pattern], body]}, ctx) do
    case extract_binding(pattern) do
      {:ok, name} ->
        if has_logger_call?(body) and not has_reraise?(body) and returns_generic?(body, name) do
          put_issue(ctx, issue_for(ctx, meta))
        else
          ctx
        end

      :skip ->
        ctx
    end
  end

  defp check_clause(_, ctx), do: ctx

  defp extract_binding({:in, _, [{name, _, ctx}, _]}) when is_atom(name) and is_atom(ctx) do
    if String.starts_with?(Atom.to_string(name), "_"), do: :skip, else: {:ok, name}
  end

  defp extract_binding({name, _, ctx}) when is_atom(name) and is_atom(ctx) do
    if String.starts_with?(Atom.to_string(name), "_"), do: :skip, else: {:ok, name}
  end

  defp extract_binding(_), do: :skip

  defp has_logger_call?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {{:., _, [{:__aliases__, _, [:Logger]}, _]}, _, _} = node, _ -> {node, true}
        node, found -> {node, found}
      end)

    found?
  end

  defp has_reraise?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {:reraise, _, _} = node, _ -> {node, true}
        node, found -> {node, found}
      end)

    found?
  end

  defp returns_generic?({:__block__, _, exprs}, name), do: generic_return?(last_expr(exprs), name)
  defp returns_generic?(expr, name), do: generic_return?(expr, name)

  defp last_expr([expr]), do: expr
  defp last_expr([_ | rest]), do: last_expr(rest)

  defp generic_return?(expr, name) do
    case expr do
      :error -> true
      {:__block__, _, [:error]} -> true
      nil -> true
      {:__block__, _, [nil]} -> true
      {:error, _} -> not uses_binding?(expr, name)
      {:{}, _, [:error | _]} -> not uses_binding?(expr, name)
      _ -> false
    end
  end

  defp uses_binding?(ast, name) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {^name, _, ctx} = node, _ when is_atom(ctx) -> {node, true}
        node, found -> {node, found}
      end)

    found?
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`rescue` logs the error but swallows it — re-raise or return the exception info.",
      trigger: "rescue",
      line_no: meta[:line]
    )
  end
end
