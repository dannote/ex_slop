defmodule ExSlop.Check.Refactor.FilterNilTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.FilterNil

  test "reports Enum.filter(fn x -> x != nil end)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.filter(fn x -> x != nil end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FilterNil)
    |> assert_issue()
  end

  test "reports Enum.filter(fn x -> x !== nil end)" do
    """
    defmodule Test do
      def foo(list) do
        Enum.filter(list, fn x -> x !== nil end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FilterNil)
    |> assert_issue()
  end

  test "reports Enum.filter(fn x -> !is_nil(x) end)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.filter(fn x -> !is_nil(x) end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FilterNil)
    |> assert_issue()
  end

  test "does NOT report Enum.filter with real predicate" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.filter(fn x -> x > 0 end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FilterNil)
    |> refute_issues()
  end

  test "does NOT report Enum.reject(&is_nil/1)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.reject(&is_nil/1)
      end
    end
    """
    |> to_source_file()
    |> run_check(FilterNil)
    |> refute_issues()
  end
end
