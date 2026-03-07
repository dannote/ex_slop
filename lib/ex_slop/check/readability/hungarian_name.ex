defmodule ExSlop.Check.Readability.HungarianName do
  use Credo.Check,
    id: "EXS3008",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Variable names with Hungarian-style type suffixes add no information
      in a dynamically typed language.

          # bad
          user_map = Repo.get(User, id) |> Map.from_struct()
          items_list = Enum.to_list(stream)
          result_tuple = {:ok, value}

          # good — the type is clear from context
          user = Repo.get(User, id) |> Map.from_struct()
          items = Enum.to_list(stream)
          result = {:ok, value}
      """
    ]

  @type_suffixes ~w(_map _list _tuple _string _bool _boolean _integer _int _float _struct _binary)

  @legitimate_names ~w(
    is_map is_list to_string to_integer to_float
    allow_list deny_list block_list white_list black_list
    wish_list check_list word_list price_list task_list
    play_list wait_list guest_list drop_list hit_list name_list
    road_map site_map heat_map mind_map key_map tree_map
    doc_string bit_string
  )a

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:=, _, [lhs, _rhs]} = ast, ctx) do
    issues = extract_variables(lhs) |> Enum.filter(&hungarian?/1)

    ctx =
      Enum.reduce(issues, ctx, fn {name, meta}, ctx ->
        put_issue(ctx, issue_for(ctx, meta, name))
      end)

    {ast, ctx}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp extract_variables({name, meta, context}) when is_atom(name) and is_atom(context) do
    [{name, meta}]
  end

  defp extract_variables({_, _, args}) when is_list(args) do
    Enum.flat_map(args, &extract_variables/1)
  end

  defp extract_variables({left, right}) do
    extract_variables(left) ++ extract_variables(right)
  end

  defp extract_variables(list) when is_list(list) do
    Enum.flat_map(list, &extract_variables/1)
  end

  defp extract_variables(_), do: []

  defp hungarian?({name, _meta}) do
    name_str = Atom.to_string(name)

    not String.starts_with?(name_str, "_") and
      name not in @legitimate_names and
      Enum.any?(@type_suffixes, &String.ends_with?(name_str, &1))
  end

  defp issue_for(ctx, meta, name) do
    format_issue(ctx,
      message:
        "Hungarian-style variable name `#{name}` — in Elixir the type is clear from context.",
      trigger: Atom.to_string(name),
      line_no: meta[:line]
    )
  end
end
