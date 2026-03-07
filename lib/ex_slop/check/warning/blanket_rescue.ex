defmodule ExSlop.Check.Warning.BlanketRescue do
  use Credo.Check,
    id: "EXS1001",
    base_priority: :high,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      `rescue _ ->` or `rescue _e ->` that returns `nil` or a generic error
      tuple swallows all exceptions, making bugs invisible.

      This is the most common AI slop pattern in Elixir. The AI adds blanket
      rescues to make code "robust", but it actually hides crashes that would
      surface real problems.

          # bad — swallows everything
          try do
            do_something()
          rescue
            _ -> nil
          end

          # bad — generic string loses all context
          rescue
            _e -> {:error, "Something went wrong"}

          # good — rescue specific exceptions
          rescue
            e in [ArgumentError, RuntimeError] ->
              Logger.warning("Failed: \#{Exception.message(e)}")
              {:error, :invalid_input}

          # good — let it crash (the BEAM way)
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

  # rescue _ -> <swallow>
  defp walk({:rescue, _, clauses} = ast, ctx) when is_list(clauses) do
    ctx = Enum.reduce(clauses, ctx, &check_clause/2)
    {ast, ctx}
  end

  # try with rescue block
  defp walk({:try, _, [[do: _, rescue: clauses]]} = ast, ctx) when is_list(clauses) do
    ctx = Enum.reduce(clauses, ctx, &check_clause/2)
    {ast, ctx}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp check_clause({:->, meta, [[pattern], body]}, ctx) do
    if blanket_pattern?(pattern) and swallows?(body) do
      put_issue(ctx, issue_for(ctx, meta))
    else
      ctx
    end
  end

  defp check_clause(_, ctx), do: ctx

  # _ or _anything
  defp blanket_pattern?({name, _, _}) when is_atom(name) do
    name |> Atom.to_string() |> String.starts_with?("_")
  end

  defp blanket_pattern?(_), do: false

  defp swallows?(nil), do: true
  defp swallows?({:__block__, _, [nil]}), do: true

  # {:error, "string literal"}
  defp swallows?({:{}, _, [:error, msg]}) when is_binary(msg), do: true
  defp swallows?({:error, msg}) when is_binary(msg), do: true
  defp swallows?({:error, {:__block__, _, [msg]}}) when is_binary(msg), do: true

  # :error
  defp swallows?(:error), do: true
  defp swallows?({:__block__, _, [:error]}), do: true

  # {:error, :atom}
  defp swallows?({:{}, _, [:error, atom]}) when is_atom(atom), do: true
  defp swallows?({:error, atom}) when is_atom(atom), do: true
  defp swallows?({:error, {:__block__, _, [atom]}}) when is_atom(atom), do: true

  defp swallows?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Blanket `rescue` swallows all exceptions — rescue specific ones or let it crash.",
      trigger: "rescue",
      line_no: meta[:line]
    )
  end
end
