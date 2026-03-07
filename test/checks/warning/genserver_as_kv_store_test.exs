defmodule ExSlop.Check.Warning.GenserverAsKvStoreTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.GenserverAsKvStore

  test "reports GenServer with {:get, key} handle_call using Map.get" do
    """
    defmodule MyCache do
      use GenServer

      def handle_call({:get, key}, _from, state) do
        {:reply, Map.get(state, key), state}
      end

      def handle_call({:put, key, value}, _from, state) do
        {:reply, :ok, Map.put(state, key, value)}
      end
    end
    """
    |> to_source_file()
    |> run_check(GenserverAsKvStore)
    |> assert_issue()
  end

  test "does NOT report GenServer with meaningful handle_call logic" do
    """
    defmodule MyWorker do
      use GenServer

      def handle_call({:get, key}, _from, state) do
        result = expensive_computation(key, state)
        {:reply, result, state}
      end
    end
    """
    |> to_source_file()
    |> run_check(GenserverAsKvStore)
    |> refute_issues()
  end

  test "does NOT report non-GenServer modules" do
    """
    defmodule MyModule do
      def get(key, map) do
        Map.get(map, key)
      end
    end
    """
    |> to_source_file()
    |> run_check(GenserverAsKvStore)
    |> refute_issues()
  end
end
