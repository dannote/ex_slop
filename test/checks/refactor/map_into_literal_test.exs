defmodule ExSlop.Check.Refactor.MapIntoLiteralTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.MapIntoLiteral

  test "reports Enum.map |> Enum.into(%{})" do
    """
    defmodule Test do
      def foo(list) do
        list
        |> Enum.map(fn {k, v} -> {k, v + 1} end)
        |> Enum.into(%{})
      end
    end
    """
    |> to_source_file()
    |> run_check(MapIntoLiteral)
    |> assert_issue()
  end

  test "reports Enum.into(Enum.map(...), %{})" do
    """
    defmodule Test do
      def foo(list) do
        Enum.into(Enum.map(list, fn {k, v} -> {k, v} end), %{})
      end
    end
    """
    |> to_source_file()
    |> run_check(MapIntoLiteral)
    |> assert_issue()
  end

  test "does NOT report Enum.into with non-empty map" do
    """
    defmodule Test do
      def foo(list) do
        list
        |> Enum.map(fn {k, v} -> {k, v} end)
        |> Enum.into(%{default: true})
      end
    end
    """
    |> to_source_file()
    |> run_check(MapIntoLiteral)
    |> refute_issues()
  end

  test "does NOT report Map.new" do
    """
    defmodule Test do
      def foo(list) do
        Map.new(list, fn {k, v} -> {k, v + 1} end)
      end
    end
    """
    |> to_source_file()
    |> run_check(MapIntoLiteral)
    |> refute_issues()
  end
end
