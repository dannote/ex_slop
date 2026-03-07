defmodule ExSlop.Check.Warning.QueryInEnumMap do
  use Credo.Check,
    id: "EXS1003",
    base_priority: :higher,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      Calling `Repo.get`, `Repo.one`, or `Repo.all` inside `Enum.map/2` is
      an N+1 query — one database round-trip per element.

          # bad — N+1 queries
          users
          |> Enum.map(fn user ->
            posts = Repo.all(from p in Post, where: p.user_id == ^user.id)
            %{user | posts: posts}
          end)

          # good — preload in one query
          users |> Repo.preload(:posts)
      """
    ]

  @repo_calls [:get, :get!, :get_by, :get_by!, :one, :one!, :all, :aggregate, :exists?]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.map(list, fn ... end) where fn body contains Repo.call
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :map]}, _, [_list, {:fn, _, _} = fun]} = ast,
         ctx
       ) do
    if contains_repo_call?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # list |> Enum.map(fn ... end)
  defp walk(
         {:|>, _,
          [
            _,
            {{:., meta, [{:__aliases__, _, [:Enum]}, :map]}, _, [{:fn, _, _} = fun]}
          ]} = ast,
         ctx
       ) do
    if contains_repo_call?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp contains_repo_call?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {{:., _, [{:__aliases__, _, repo}, fun]}, _, _} = node, _found ->
          if fun in @repo_calls and repo_module?(repo) do
            {node, true}
          else
            {node, false}
          end

        node, found ->
          {node, found}
      end)

    found?
  end

  defp repo_module?(modules) when is_list(modules) do
    modules |> List.last() == :Repo
  end

  defp repo_module?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Database query inside `Enum.map/2` — this is an N+1 query. Use `Repo.preload/2` or a join.",
      trigger: "map",
      line_no: meta[:line]
    )
  end
end
