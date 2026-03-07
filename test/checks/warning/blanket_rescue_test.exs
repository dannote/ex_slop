defmodule ExSlop.Check.Warning.BlanketRescueTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.BlanketRescue

  test "reports rescue _ -> nil" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(BlanketRescue)
    |> assert_issue()
  end

  test "reports rescue _e -> {:error, \"string\"}" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          _e -> {:error, "Something went wrong"}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(BlanketRescue)
    |> assert_issue()
  end

  test "reports rescue _ -> :error" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          _ -> :error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(BlanketRescue)
    |> assert_issue()
  end

  test "does NOT report rescue with specific exception" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e in ArgumentError -> {:error, Exception.message(e)}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(BlanketRescue)
    |> refute_issues()
  end

  test "does NOT report rescue _ with meaningful body" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          _ -> Logger.error("boom"); reraise "boom", __STACKTRACE__
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(BlanketRescue)
    |> refute_issues()
  end
end
