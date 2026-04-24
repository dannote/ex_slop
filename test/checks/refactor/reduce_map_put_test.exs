defmodule ExSlop.Check.Refactor.ReduceMapPutTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.ReduceMapPut

  test "reports Enum.reduce with %{} and Map.put" do
    """
    defmodule Example do
      def build_map(events) do
        Enum.reduce(events, %{}, fn event, acc ->
          Map.put(acc, event.id, event)
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(ReduceMapPut)
    |> assert_issue()
  end

  test "reports piped Enum.reduce with %{} and Map.put" do
    """
    defmodule Example do
      def build_map(events) do
        events
        |> Enum.reduce(%{}, fn event, acc ->
          Map.put(acc, event.id, event)
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(ReduceMapPut)
    |> assert_issue()
  end

  test "does NOT report Enum.reduce with non-empty initial map" do
    """
    defmodule Example do
      def update_map(events) do
        Enum.reduce(events, %{default: true}, fn event, acc ->
          Map.put(acc, event.id, event)
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(ReduceMapPut)
    |> refute_issues()
  end

  test "does NOT report Map.new" do
    """
    defmodule Example do
      def build_map(events) do
        Map.new(events, fn event -> {event.id, event} end)
      end
    end
    """
    |> to_source_file()
    |> run_check(ReduceMapPut)
    |> refute_issues()
  end

  test "does NOT report Enum.reduce with non-Map.put body" do
    """
    defmodule Example do
      def count(events) do
        Enum.reduce(events, %{}, fn event, acc ->
          Map.update(acc, event.type, 1, &(&1 + 1))
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(ReduceMapPut)
    |> refute_issues()
  end
end
