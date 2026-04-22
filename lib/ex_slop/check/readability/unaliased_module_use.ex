defmodule ExSlop.Check.Readability.UnaliasedModuleUse do
  use Credo.Check,
    id: "EXS3009",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    param_defaults: [min_count: 2],
    explanations: [
      check: """
      LLMs tend to inline fully-qualified module names instead of aliasing them.
      This produces noisy, harder-to-read code.

          # bad — AI slop
          def run(source_file) do
            Credo.Code.prewalk(source_file, &walk/2, ctx)
            Credo.Code.remove_metadata(pattern)
            Credo.Code.remove_metadata(body)
          end

          # good
          alias Credo.Code

          def run(source_file) do
            Code.prewalk(source_file, &walk/2, ctx)
            Code.remove_metadata(pattern)
            Code.remove_metadata(body)
          end
      """,
      params: [
        min_count: "Minimum uses of a module before flagging (default: 2)."
      ]
    ]

  alias Credo.Code
  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    min_count = Params.get(params, :min_count, __MODULE__)
    ctx = Context.build(source_file, params, __MODULE__)

    result = Code.prewalk(source_file, &walk/2, ctx)

    result.issues
    |> Enum.group_by(& &1.trigger)
    |> Enum.filter(fn {_trigger, issues} -> length(issues) >= min_count end)
    |> Enum.flat_map(fn {_trigger, issues} -> issues end)
  end

  defp walk({:defmodule, _, _} = ast, ctx) do
    aliases = collect_aliases(ast)
    mod_deps = Code.Module.modules(ast)

    ctx =
      Code.prewalk(
        ast,
        &find_issues/2,
        Map.merge(ctx, %{aliases: aliases, mod_deps: mod_deps})
      )

    {ast, ctx}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp collect_aliases(ast) do
    {_, %{full: full, local: local}} =
      Macro.prewalk(ast, %{full: [], local: MapSet.new()}, fn
        {:alias, _, [{:__aliases__, _, parts}, [as: {:__aliases__, _, local_parts}]]} = node,
        %{full: full, local: local} = acc ->
          {node,
           %{
             acc
             | full: [Name.full(parts) | full],
               local: MapSet.put(local, Name.full(local_parts))
           }}

        {:alias, _, [{:__aliases__, _, parts} | _]} = node, %{full: full, local: local} = acc ->
          {node,
           %{acc | full: [Name.full(parts) | full], local: MapSet.put(local, Name.last(parts))}}

        node, acc ->
          {node, acc}
      end)

    %{
      full: (full ++ Code.Module.aliases(ast)) |> Enum.uniq(),
      local: local
    }
  end

  # Ignore module attributes — typespecs legitimately use FQNs
  defp find_issues({:@, _, _}, ctx) do
    {nil, ctx}
  end

  # Credo.Code.prewalk(...)
  defp find_issues({:., meta, [{:__aliases__, _, mod_list}, fun_atom]} = ast, ctx)
       when is_list(mod_list) and is_atom(fun_atom) and length(mod_list) >= 2 do
    do_find_issues(ast, mod_list, meta, ctx)
  end

  defp find_issues(ast, ctx) do
    {ast, ctx}
  end

  defp do_find_issues(ast, mod_list, meta, ctx) do
    %{
      aliases: aliases,
      mod_deps: mod_deps
    } = ctx

    cond do
      Enum.any?(mod_list, &unquote?/1) ->
        {ast, ctx}

      aliased?(mod_list, aliases) ->
        {ast, ctx}

      conflicting_module?(mod_list, mod_deps) ->
        {ast, ctx}

      true ->
        trigger = Name.full(mod_list)

        {ast, put_issue(ctx, issue_for(ctx, trigger, meta))}
    end
  end

  defp unquote?({:unquote, _, _}), do: true
  defp unquote?(_), do: false

  defp aliased?(mod_list, %{full: full, local: local}) do
    full_name = Name.full(mod_list)

    cond do
      full_name in full -> true
      length(mod_list) >= 2 and Name.full([hd(mod_list)]) in local -> true
      true -> false
    end
  end

  defp conflicting_module?(mod_list, mod_deps) do
    full_name = Name.full(mod_list)
    last_name = Name.last(mod_list)

    (mod_deps -- [full_name])
    |> Enum.filter(&(Name.parts_count(&1) > 1))
    |> Enum.map(&Name.last/1)
    |> Enum.any?(&(&1 == last_name))
  end

  defp issue_for(ctx, trigger, meta) do
    format_issue(ctx,
      message: "Fully-qualified `#{trigger}` used repeatedly — add an `alias`.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
