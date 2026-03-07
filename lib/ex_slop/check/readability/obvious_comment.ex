defmodule ExSlop.Check.Readability.ObviousComment do
  use Credo.Check,
    id: "EXS3003",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Comments that restate what the next line of code does are noise.

          # bad
          # Fetch the user from the database
          user = Repo.get(User, id)

          # Create the changeset
          changeset = User.changeset(user, attrs)

          # Return the result
          {:ok, changeset}

          # good — no comment needed, the code is clear

          # good — explains WHY
          # Preload to avoid N+1 in the template
          user = Repo.get(User, id) |> Repo.preload(:posts)
      """
    ]

  @obvious_pattern ~r/\A\s*#\s*(?:Fetch|Get|Create|Build|Update|Delete|Remove|Set|Parse|Convert|Validate|Check|Process|Handle|Format|Transform|Normalize|Calculate|Compute|Extract|Initialize|Define|Assign|Store|Save|Insert|Add|Return|Ensure|Verify)\s+(?:the|a|an)\s/i

  @keeper_pattern ~r/\bTODO\b|\bFIXME\b|\bHACK\b|\bNOTE\b|\bSAFETY\b|\bWARN\b|\bBUG\b|\bXXX\b|\bPERF\b/

  @tool_directive ~r/credo:|dialyzer:|sobelow:|coveralls|noinspection|elixir-ls|ExUnit/

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> Credo.SourceFile.lines()
    |> Enum.reduce(ctx, fn {line_no, line}, ctx ->
      trimmed = String.trim(line)

      if obvious?(trimmed) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp obvious?(line) do
    Regex.match?(@obvious_pattern, line) and
      not Regex.match?(@keeper_pattern, line) and
      not Regex.match?(@tool_directive, line)
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Obvious comment restates what the code does — remove it or explain WHY.",
      trigger: "#",
      line_no: line_no
    )
  end
end
