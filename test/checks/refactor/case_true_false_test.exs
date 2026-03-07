defmodule ExSlop.Check.Refactor.CaseTrueFalseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.CaseTrueFalse

  test "reports case with true/false clauses" do
    """
    defmodule Test do
      def foo(x) do
        case is_binary(x) do
          true -> :yes
          false -> :no
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseTrueFalse)
    |> assert_issue()
  end

  test "reports case with false/true clauses (reversed)" do
    """
    defmodule Test do
      def foo(x) do
        case is_binary(x) do
          false -> :no
          true -> :yes
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseTrueFalse)
    |> assert_issue()
  end

  test "does NOT report case with atom patterns like :ok/:error" do
    """
    defmodule Test do
      def foo(x) do
        case x do
          :ok -> :great
          :error -> :bad
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseTrueFalse)
    |> refute_issues()
  end

  test "does NOT report case with 3+ clauses" do
    """
    defmodule Test do
      def foo(x) do
        case x do
          true -> :yes
          false -> :no
          nil -> :maybe
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CaseTrueFalse)
    |> refute_issues()
  end
end
