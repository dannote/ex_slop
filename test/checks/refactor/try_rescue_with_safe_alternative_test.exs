defmodule ExSlop.Check.Refactor.TryRescueWithSafeAlternativeTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.TryRescueWithSafeAlternative

  test "reports try/rescue around String.to_integer" do
    """
    defmodule Test do
      def foo(value) do
        try do
          String.to_integer(value)
        rescue
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(TryRescueWithSafeAlternative)
    |> assert_issue()
  end

  test "reports try/rescue around Jason.decode!" do
    """
    defmodule Test do
      def foo(json) do
        try do
          Jason.decode!(json)
        rescue
          _ -> {:error, "invalid json"}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(TryRescueWithSafeAlternative)
    |> assert_issue()
  end

  test "reports try/rescue around Map.fetch!" do
    """
    defmodule Test do
      def foo(map, key) do
        try do
          Map.fetch!(map, key)
        rescue
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(TryRescueWithSafeAlternative)
    |> assert_issue()
  end

  test "does NOT report try/rescue around custom function" do
    """
    defmodule Test do
      def foo(value) do
        try do
          MyModule.risky_call(value)
        rescue
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(TryRescueWithSafeAlternative)
    |> refute_issues()
  end

  test "does NOT report proper error handling" do
    """
    defmodule Test do
      def foo(value) do
        case Integer.parse(value) do
          {int, ""} -> {:ok, int}
          _ -> {:error, :invalid}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(TryRescueWithSafeAlternative)
    |> refute_issues()
  end
end
