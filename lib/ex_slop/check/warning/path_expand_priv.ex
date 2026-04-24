defmodule ExSlop.Check.Warning.PathExpandPriv do
  use Credo.Check,
    id: "EXS1006",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      Using `Path.expand("...priv...", __DIR__)` to locate application resources
      is fragile — it depends on the source layout and breaks in releases.
      Use `Application.app_dir/2` instead.

          # bad — fragile, breaks in releases
          Path.expand("../../priv/prompts/system.md", __DIR__)

          # good — works in dev, test, and releases
          Application.app_dir(:my_app, "priv/prompts/system.md")
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., meta, [{:__aliases__, _, [:Path]}, :expand]}, _, [path_arg | _]} = ast, ctx) do
    if path_references_priv?(path_arg) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp path_references_priv?({:<<>>, _, parts}) when is_list(parts) do
    Enum.any?(parts, fn
      str when is_binary(str) -> String.contains?(str, "priv")
      _ -> false
    end)
  end

  defp path_references_priv?(str) when is_binary(str), do: String.contains?(str, "priv")
  defp path_references_priv?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Use `Application.app_dir/2` instead of `Path.expand(\"...priv...\", __DIR__)` — it works in dev, test, and releases.",
      trigger: "Path.expand",
      line_no: meta[:line]
    )
  end
end
