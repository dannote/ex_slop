defmodule ExSlop.Check.Refactor.StringConcatInReduceTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.StringConcatInReduce

  test "reports Enum.reduce with string concat" do
    ~S"""
    defmodule Test do
      def foo(list) do
        Enum.reduce(list, "", fn x, acc -> acc <> x end)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> assert_issue()
  end

  test "reports piped Enum.reduce with string concat" do
    ~S"""
    defmodule Test do
      def foo(list) do
        list |> Enum.reduce("", fn x, acc -> acc <> to_string(x) end)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> assert_issue()
  end

  test "reports acc on right side of <>" do
    ~S"""
    defmodule Test do
      def foo(list) do
        Enum.reduce(list, "", fn x, acc -> x <> acc end)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> assert_issue()
  end

  test "does NOT report list accumulator" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reduce(list, [], fn x, acc -> [x | acc] end)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> refute_issues()
  end

  test "does NOT report no concat in body" do
    ~S"""
    defmodule Test do
      def foo(list) do
        Enum.reduce(list, "", fn x, acc -> acc end)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> refute_issues()
  end

  test "does NOT report Enum.join" do
    """
    defmodule Test do
      def foo(list) do
        Enum.join(list)
      end
    end
    """
    |> to_source_file()
    |> run_check(StringConcatInReduce)
    |> refute_issues()
  end
end
