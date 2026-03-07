defmodule ExSlop.Check.Warning.GenserverAsKvStore do
  use Credo.Check,
    id: "EXS1005",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      A GenServer that implements `handle_call({:get, key}, ...)` with a body
      that just calls `Map.get(state, key)` is reimplementing a key-value store.
      The BEAM already provides `Agent` and ETS for this.

          # bad — GenServer as a dumb key-value wrapper
          defmodule MyCache do
            use GenServer

            def handle_call({:get, key}, _from, state) do
              {:reply, Map.get(state, key), state}
            end

            def handle_call({:put, key, value}, _from, state) do
              {:reply, :ok, Map.put(state, key, value)}
            end
          end

          # good — use Agent
          defmodule MyCache do
            use Agent

            def start_link(initial) do
              Agent.start_link(fn -> initial end, name: __MODULE__)
            end

            def get(key), do: Agent.get(__MODULE__, &Map.get(&1, key))
            def put(key, value), do: Agent.update(__MODULE__, &Map.put(&1, key, value))
          end

          # good — use ETS
          :ets.new(:cache, [:named_table, :public])
          :ets.insert(:cache, {key, value})
          :ets.lookup(:cache, key)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # def handle_call({:get, key}, _from, state) do ... end
  defp walk(
         {:def, meta,
          [
            {:handle_call, _,
             [
               {:get, _key},
               _from,
               _state
             ]},
            [do: body]
          ]} = ast,
         ctx
       ) do
    if body_uses_map_get?(body) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp body_uses_map_get?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {{:., _, [{:__aliases__, _, [:Map]}, :get]}, _, _} = node, _ ->
          {node, true}

        node, found ->
          {node, found}
      end)

    found?
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "GenServer reimplements a key-value store — use `Agent`, ETS, or a plain `Map` instead.",
      trigger: "handle_call",
      line_no: meta[:line]
    )
  end
end
