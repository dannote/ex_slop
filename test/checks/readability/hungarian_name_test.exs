defmodule ExSlop.Check.Readability.HungarianNameTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.HungarianName

  test "reports `user_map = %{}`" do
    """
    defmodule Test do
      def foo do
        user_map = %{}
        user_map
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> assert_issue(fn issue ->
      assert issue.trigger == "user_map"
    end)
  end

  test "reports `items_list = []`" do
    """
    defmodule Test do
      def foo do
        items_list = []
        items_list
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> assert_issue(fn issue ->
      assert issue.trigger == "items_list"
    end)
  end

  test "does NOT report `_ignored_list = []`" do
    """
    defmodule Test do
      def foo do
        _ignored_list = []
        :ok
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end

  test "does NOT report `user = %{}`" do
    """
    defmodule Test do
      def foo do
        user = %{}
        user
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end

  test "does NOT report `allow_list`" do
    """
    defmodule Test do
      def foo do
        allow_list = [:admin, :editor]
        allow_list
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end
end
