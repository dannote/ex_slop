defmodule ExSlop.Check.Readability.DocFalseOnPublicFunction do
  use Credo.Check,
    id: "EXS3005",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      `@doc false` on a public function (`def`, not `defp`) is a code smell.
      If the function is truly internal, make it `defp`. If it's public API,
      document it.

      The only valid use is on callbacks (`@impl true`) where the behaviour's
      doc suffices — this check skips those.

          # bad — cargo-culted from Phoenix generators
          @doc false
          def changeset(user, attrs) do

          # good — either document it
          @doc "Casts and validates registration fields."
          def changeset(user, attrs) do

          # good — or make it private
          defp changeset(user, attrs) do
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Track @doc false, then check if followed by def (not defp)
  defp walk({:@, _, [{:doc, _, [false]}]} = ast, ctx) do
    {ast, Map.put(ctx, :doc_false_line, ast |> source_line())}
  end

  defp walk({:@, _, [{:impl, _, [true]}]} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk({:@, _, [{:impl, _, [{:__block__, _, [true]}]}]} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk({:def, meta, [{name, _, _} | _]} = ast, ctx) when is_atom(name) do
    if Map.has_key?(ctx, :doc_false_line) do
      ctx = Map.delete(ctx, :doc_false_line)
      {ast, put_issue(ctx, issue_for(ctx, meta, name))}
    else
      {ast, ctx}
    end
  end

  # Reset on defp — that's fine
  defp walk({:defp, _, _} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  # Reset on any other @doc / @moduledoc
  defp walk({:@, _, [{attr, _, _}]} = ast, ctx) when attr in [:doc, :moduledoc] do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp source_line({:@, meta, _}), do: meta[:line]
  defp source_line(_), do: nil

  defp issue_for(ctx, meta, name) do
    format_issue(ctx,
      message: "`@doc false` on public `def #{name}` — document it or make it `defp`.",
      trigger: "@doc false",
      line_no: meta[:line]
    )
  end
end
