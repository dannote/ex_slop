defmodule ExSlop.Check.Warning.DualKeyAccess do
  use Credo.Check,
    id: "EXS1007",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Map.get(map, :atom) || Map.get(map, "string")` checks both atom and
      string keys because the data shape is unknown. This is a sign of
      defensive coding where the shape should be known.

      Use `Map.get(map, key)` with a known key type, or normalize the map
      once at the boundary.

          # bad — doesn't know if keys are atoms or strings
          Map.get(usage, :input_tokens) || Map.get(usage, "input_tokens") || 0

          # good — normalize once at the boundary, then use atom keys
          usage = Map.new(usage, fn {k, v} -> {to_atom(k), v} end)
          Map.get(usage, :input_tokens, 0)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Map.get(map, :atom_key) || Map.get(map, "string_key")
  defp walk(
         {:||, meta,
          [
            {{:., _, [{:__aliases__, _, [:Map]}, :get]}, _, [map, atom_key]},
            {{:., _, [{:__aliases__, _, [:Map]}, :get]}, _, [map2, string_key]}
          ]} = ast,
         ctx
       )
      when is_atom(atom_key) and is_binary(string_key) do
    if same_variable?(map, map2) and Atom.to_string(atom_key) == string_key do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp same_variable?({name, _, ctx1}, {name, _, ctx2}) when is_atom(name) and is_atom(ctx1) and is_atom(ctx2),
    do: true

  defp same_variable?(_, _), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Dual-key `Map.get(m, :key) || Map.get(m, \"key\")` — normalize the map once instead of checking both key types.",
      trigger: "Map.get",
      line_no: meta[:line]
    )
  end
end
