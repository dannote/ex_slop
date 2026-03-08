defmodule ExSlop.Check.Refactor.WithIdentityDoTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.WithIdentityDo

  test "reports identity with/do" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityDo)
    |> assert_issue()
  end

  test "reports identity with/do with different var name" do
    """
    defmodule Test do
      def foo do
        with {:ok, val} <- fetch() do
          {:ok, val}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityDo)
    |> assert_issue()
  end

  test "does NOT report with/do that transforms result" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, transform(result)}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityDo)
    |> refute_issues()
  end

  test "does NOT report multi-clause with" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- a(),
             {:ok, other} <- b(result) do
          {:ok, other}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityDo)
    |> refute_issues()
  end

  test "does NOT report with/do that has else" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, _} -> {:error, :failed}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityDo)
    |> refute_issues()
  end
end
