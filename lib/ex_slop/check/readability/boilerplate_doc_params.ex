defmodule ExSlop.Check.Readability.BoilerplateDocParams do
  use Credo.Check,
    id: "EXS3007",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      `@doc` strings with a `## Parameters` section that merely restates
      the function signature add no value.

          # bad
          @doc \"""
          Renders the index page.

          ## Parameters

          - conn: The connection struct
          - params: A map of parameters
          \"""
          def index(conn, params)

          # good — document constraints, not names
          @doc \"""
          Renders the index page.

          ## Parameters

          - params: Must include `"page"` (integer >= 1) and
            optionally `"per_page"` (default 20, max 100).
          \"""

          # good — no ## Parameters section at all
          @doc \"""
          Renders the index page, paginated.
          \"""
      """
    ]

  @section_heading ~r/^##\s+(?:Parameters|Params|Arguments|Args)\s*$/m
  @boilerplate_entry ~r/^\s*-\s+`?(?:conn|params|socket|assigns)`?\s*[-:–]\s*(?:the\s+)?(?:connection(?:\s+struct)?|(?:a\s+)?map\s+of\s+param(?:eter)?s|(?:the\s+)?socket(?:\s+struct)?|(?:the\s+)?assigns(?:\s+map)?)\s*\.?\s*$/im

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:doc, meta, [docstring]}]} = ast, ctx) when is_binary(docstring) do
    if boilerplate_params?(docstring) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp boilerplate_params?(docstring) do
    Regex.match?(@section_heading, docstring) and Regex.match?(@boilerplate_entry, docstring)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Boilerplate `## Parameters` doc restates the function signature — document constraints or remove it.",
      trigger: "@doc",
      line_no: meta[:line]
    )
  end
end
