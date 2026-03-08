defmodule ExSlop.Check.Refactor.RejectNilTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.RejectNil

  test "reports Enum.reject(fn x -> x == nil end)" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reject(list, fn x -> x == nil end)
      end
    end
    """
    |> to_source_file()
    |> run_check(RejectNil)
    |> assert_issue()
  end

  test "reports list |> Enum.reject(fn x -> x === nil end)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.reject(fn x -> x === nil end)
      end
    end
    """
    |> to_source_file()
    |> run_check(RejectNil)
    |> assert_issue()
  end

  test "reports Enum.reject(fn x -> is_nil(x) end)" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reject(list, fn x -> is_nil(x) end)
      end
    end
    """
    |> to_source_file()
    |> run_check(RejectNil)
    |> assert_issue()
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
    |> run_check(RejectNil)
    |> refute_issues()
  end

  test "does NOT report Enum.reject with non-nil check" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reject(list, fn x -> x == 0 end)
      end
    end
    """
    |> to_source_file()
    |> run_check(RejectNil)
    |> refute_issues()
  end
end
