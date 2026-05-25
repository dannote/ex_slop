defmodule ExSlop.Check.Refactor.LengthComparisonTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.LengthComparison

  test "reports length(list) == 0 in a function body" do
    """
    defmodule Test do
      def foo(list) do
        if length(list) == 0, do: :empty, else: :not_empty
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> assert_issue()
  end

  test "reports length(list) > 0 in a guard" do
    """
    defmodule Test do
      def foo(list) when length(list) > 0, do: list
      def foo(_), do: nil
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> assert_issue()
  end

  test "reports a threshold comparison length(items) <= 5" do
    """
    defmodule Test do
      def foo(items) do
        length(items) <= 5
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> assert_issue()
  end

  test "reports the literal on the left: 0 < length(list)" do
    """
    defmodule Test do
      def foo(list) do
        0 < length(list)
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> assert_issue()
  end

  test "reports every comparison operator" do
    for op <- ["==", "!=", ">", "<", ">=", "<="] do
      """
      defmodule Test do
        def foo(list) do
          length(list) #{op} 3
        end
      end
      """
      |> to_source_file()
      |> run_check(LengthComparison)
      |> assert_issue()
    end
  end

  test "does NOT report length/1 used without a comparison" do
    """
    defmodule Test do
      def foo(list) do
        count = length(list)
        Logger.info("got \#{count} items")
        count
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> refute_issues()
  end

  test "does NOT report length compared to a variable" do
    """
    defmodule Test do
      def foo(list, max) do
        length(list) > max
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> refute_issues()
  end

  test "does NOT report two lengths compared to each other" do
    """
    defmodule Test do
      def foo(a, b) do
        length(a) == length(b)
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> refute_issues()
  end

  test "does NOT report String.length/1 against a literal" do
    """
    defmodule Test do
      def foo(string) do
        String.length(string) == 0
      end
    end
    """
    |> to_source_file()
    |> run_check(LengthComparison)
    |> refute_issues()
  end
end
