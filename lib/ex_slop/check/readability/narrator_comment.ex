defmodule ExSlop.Check.Readability.NarratorComment do
  use Credo.Check,
    id: "EXS3008",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Inline comments that narrate code in first-person plural ("we") or
      with "Let's" / "Here we" are a hallmark of LLM-generated code.
      They add no value — either delete them or replace with a comment
      that explains WHY.

          # bad
          # Here we fetch the user from the database
          user = Repo.get!(User, id)

          # Now we validate the input
          changeset = User.changeset(user, attrs)

          # Let's create a new changeset
          changeset = change(user)

          # good — no comment needed, the code is clear

          # good — explains WHY
          # Bypass validation for admin imports (they're pre-validated upstream)
          Repo.insert!(changeset, skip_validations: true)
      """
    ]

  @narrator_pattern ~r/\A\s*#\s*(?:Here\s+we|Now\s+we|Let'?s|Next,?\s+we|Finally,?\s+we|First,?\s+we)\s/i

  @keeper_pattern ~r/\bTODO\b|\bFIXME\b|\bHACK\b|\bNOTE\b|\bSAFETY\b|\bWARN\b|\bBUG\b|\bXXX\b|\bPERF\b/

  @tool_directive ~r/credo:|dialyzer:|sobelow:|coveralls|noinspection|elixir-ls|ExUnit/

  @explanation_pattern ~r/because|since|due to|avoid|prevent|otherwise|in order|so that|so we|ensure|in case|necessary|need to handle|workaround|cannot|can't|shouldn't|must not|not supported|bootstrap|compat/i

  @max_length 60

  alias Credo.SourceFile
  alias ExSlop.DocRanges

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    doc_ranges = DocRanges.build(SourceFile.source(source_file))

    source_file
    |> SourceFile.lines()
    |> Enum.reduce(ctx, fn {line_no, line}, ctx ->
      trimmed = String.trim(line)

      if not DocRanges.inside_doc?(line_no, doc_ranges) and narrator?(trimmed) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp narrator?(line) do
    comment_body = extract_comment_body(line)

    comment_body != nil and
      String.length(comment_body) <= @max_length and
      Regex.match?(@narrator_pattern, line) and
      not Regex.match?(@keeper_pattern, line) and
      not Regex.match?(@tool_directive, line) and
      not Regex.match?(@explanation_pattern, comment_body)
  end

  defp extract_comment_body(line) do
    case Regex.run(~r/\A\s*#\s*(.+)/, line) do
      [_, body] -> body
      _ -> nil
    end
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Narrator comment ('We need to...', 'Here we...') — either remove or explain WHY.",
      trigger: "#",
      line_no: line_no
    )
  end
end
