defmodule ExSlop.Check.Readability.DocRestatesName do
  use Credo.Check,
    id: "EXS3002",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      One-liner `@doc` that just restates the function name adds no value.

          # bad — "Creates a user" on `create_user/1`
          @doc "Creates a new user."
          def create_user(attrs)

          @doc "Deletes the given post."
          def delete_post(post)

          # good — explains constraints or behavior
          @doc "Soft-deletes by setting `deleted_at`; can be undone within 30 days."
          def delete_post(post)

          # good — just omit the doc entirely
          def create_user(attrs)
      """
    ]

  @verbs ~w(create creates creating update updates updating delete deletes deleting
    get gets getting fetch fetches fetching find finds finding
    list lists listing return returns returning build builds building
    set sets setting remove removes removing parse parses parsing
    format formats formatting convert converts converting
    validate validates validating check checks checking
    handle handles handling process processes processing
    start starts starting stop stops stopping
    send sends sending receive receives receiving
    add adds adding put puts putting)

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:doc, meta, [docstring]}]} = ast, ctx) when is_binary(docstring) do
    trimmed = String.trim(docstring)

    if single_sentence?(trimmed) and restates_verb?(trimmed) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp single_sentence?(doc) do
    not String.contains?(doc, "\n") and
      String.length(doc) < 120 and
      Regex.match?(~r/^[A-Z][^.]*\.?\s*$/, doc)
  end

  defp restates_verb?(doc) do
    first_word = doc |> String.split(~r/\s+/, parts: 2) |> hd() |> String.downcase()
    first_word in @verbs
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`@doc` restates the function name — explain constraints/behavior or remove it.",
      trigger: "@doc",
      line_no: meta[:line]
    )
  end
end
