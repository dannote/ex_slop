defmodule ExSlop.Check.Readability.SectionDivider do
  use Credo.Check,
    id: "EXS3006",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Section divider comments suggest the module is doing too much.
      Extract each section into its own module instead.

          # bad
          defmodule MyApp.Users do
            # ============
            # Public API
            # ============

            def create(attrs), do: ...

            # --- Helpers ---

            defp validate(attrs), do: ...
          end

          # good — separate modules
          defmodule MyApp.Users do
            def create(attrs), do: ...
          end

          defmodule MyApp.Users.Validation do
            def validate(attrs), do: ...
          end
      """
    ]

  @divider_pattern ~r/\A\s*#\s*[=\-~#*]{3,}/
  @skip_pattern ~r/\b(?:TODO|FIXME|HACK|NOTE|SAFETY|credo:|dialyzer:|sobelow:)/

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> Credo.SourceFile.lines()
    |> Enum.reduce(ctx, fn {line_no, line}, ctx ->
      trimmed = String.trim(line)

      if Regex.match?(@divider_pattern, trimmed) and not Regex.match?(@skip_pattern, trimmed) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Section divider comment — extract into separate modules instead.",
      trigger: "#",
      line_no: line_no
    )
  end
end
