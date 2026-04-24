defmodule ExSlop.Check.Warning.NilOrEmptyStringCheckTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.NilOrEmptyStringCheck

  test "reports expr in [nil, \"\"]" do
    """
    defmodule Example do
      def put_default(params, key, default) do
        if Map.get(params, key) in [nil, ""] do
          Map.put(params, key, default)
        else
          params
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(NilOrEmptyStringCheck)
    |> assert_issue()
  end

  test "reports expr in [\"\", nil] inside if" do
    """
    defmodule Example do
      def check(x) do
        if x in ["", nil], do: :empty, else: :present
      end
    end
    """
    |> to_source_file()
    |> run_check(NilOrEmptyStringCheck)
    |> assert_issue()
  end

  test "does NOT report expr in [nil]" do
    """
    defmodule Example do
      def check(x) do
        x in [nil]
      end
    end
    """
    |> to_source_file()
    |> run_check(NilOrEmptyStringCheck)
    |> refute_issues()
  end

  test "does NOT report expr in [\"a\", \"b\"]" do
    """
    defmodule Example do
      def check(x) do
        x in ["a", "b"]
      end
    end
    """
    |> to_source_file()
    |> run_check(NilOrEmptyStringCheck)
    |> refute_issues()
  end

  test "does NOT report is_nil check" do
    """
    defmodule Example do
      def check(x) do
        is_nil(x)
      end
    end
    """
    |> to_source_file()
    |> run_check(NilOrEmptyStringCheck)
    |> refute_issues()
  end
end
